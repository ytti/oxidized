require 'sinatra/base'
require 'sinatra/json'
require 'haml'
require 'pp'
module Oxidized
  module API
    class WebApp < Sinatra::Base

      get '/' do
        redirect '/nodes'
      end

      get '/nodes.?:format?' do
        @data = nodes.list.map do |node|
          node[:status]    = 'never'
          node[:time]      = 'never'
          node[:group]     = 'default' unless node[:group]
          if node[:last]
            node[:status] = node[:last][:status]
            node[:time]   = node[:last][:end]
          end
          node
        end
        out :nodes
      end

      get '/reload.?:format?' do
        nodes.load
        @data = 'reloaded list of nodes'
        out
      end


      get '/node/fetch/:node' do
        node, @json = route_parse :node
        @data = nodes.fetch node, nil
        out :text
      end

      get '/node/fetch/:group/:node' do
        node, @json = route_parse :node
        @data = nodes.fetch node, params[:group]
        out :text
      end


      get '/node/next/:node' do
        node, @json = route_parse :node
        nodes.next node
        redirect '/nodes' unless @json
        @data = 'ok'
        out
      end

      # use this to attach author/email/message to commit
      put '/node/next/:node' do
        node, @json = route_parse :node
        opt = JSON.load request.body.read
        nodes.next node, opt
        redirect '/nodes' unless @json
        @data = 'ok'
        out
      end

      get '/node/show/:node' do
        node, @json = route_parse :node
        @data = nodes.show node
        out :node
      end

      #get '/node/:node' do
      #  @data = nodes.show params[:node]
      #  out
      #end

      def out template=:default
        if @json or params[:format] == 'json'
          json @data
        elsif template == :text
          content_type :text
          @data
        else
          haml template
        end
      end

      def nodes
        settings.nodes
      end

      def route_parse param
        json = false
        e = params[param].split '.'
        if e.last == 'json'
          e.pop
          json = true
        end
        [e.join('.'), json]
      end
    end
  end
end
