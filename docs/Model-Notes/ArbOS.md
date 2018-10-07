# Arbor Networks ArbOS notes

If you are running ArbOS version 7 or lower then you may need to update the model to remove `exec true`:

```ruby
  cfg :ssh do
    pre_logout 'exit'
  end
```

Back to [Model-Notes](README.md)
