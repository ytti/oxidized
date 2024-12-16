# Make sure these targets always run
.PHONY: help rights clean-rights

help:
	@: $(info $(HELP))

rights:
	podman unshare chown -R 30000:30000 oxidized-config oxidized-ssh
	podman unshare chown -R 30001 gitserver/repo.git

clean-rights:
	podman unshare chown -R 0:0 *

start: gitserver-createrepo rights images
	if [ -f oxidized-config/config ]; then \
	  podman-compose -p oxidized up ; \
	else { \
	  echo "\n########\noxidized-config/config does not exist"; \
	  echo "create one or copy an example in the folder"; \
	} fi

run: start

stop:
	podman-compose -p oxidized down
	$(MAKE) clean-rights

start-local:
	if [ -f oxidized-config/config.local ]; then \
	  cp oxidized-config/config.local oxidized-config/config; \
	else \
	  echo "\n########\noxidized-config/config.local does not exist"; \
	fi
	$(MAKE) start

stop-local: stop
	if [ -f oxidized-config/config.local ]; then \
	  git checkout -- oxidized-config/config; \
	else \
	  echo "\n########\noxidized-config/config.local does not exist"; \
	fi

# creates a container image for the model simulation
model-image:
	podman image exists local/model || \
	  podman build -t local/model -f model-simulation/Dockerfile-model .

model-clean:
	podman rmi local/model

# creates a container image for gitserver
gitserver-image:
	podman image exists local/gitserver || \
	  podman build -t local/gitserver gitserver/

# create the repo repo.git inside the gitserver mapped volume
gitserver-createrepo: clean-rights
	if [ ! -d gitserver/repo.git ]; then \
	  git init --bare gitserver/repo.git; \
	fi

gitserver-clean:
	podman rmi local/gitserver
	rm -rf gitserver/repo.git

gitserver-getkey:
	podman exec --user oxidized -t oxidized_oxidized_1 sh -c "ssh-keyscan gitserver > /home/oxidized/.ssh/known_hosts"

# build all helper containter images
images: model-image gitserver-image oxidized-image

# build the oxidized image from the curent repository
oxidized-image:
	  podman build -t oxidized:`git describe --tags` -t oxidized:latest ../../

# removes the oxidized image
oxidized-image-clean:
	podman rmi local/oxidized

# run evey clean line, even if the previous fails
clean:
	-$(MAKE) stop-local
	-$(MAKE) model-clean
	-$(MAKE) gitserver-clean
	-$(MAKE) oxidized-image-clean

define HELP
make help           - This help
make rights         - Change the rights of mapped folders for the users inside
                      the container
make clean-rights   - Revert the rights of mapped folders to the local user
make start          - Start the pod with all containers (alias - make run)
                      You can interrupt with Ctrl-C, but make sure you run
                      'make stop' to realy stop the container
make stop           - Stop the pod
make start-local    - Starts the pod with the local configuration
                      oxidized-config/config.local
make stop-local     - Stops the pod and restores
                      oxidized-config/config from git
make gitserver-getkey - stores the public key of the gitserver into
                      oxidized-ssh/known_hosts (the pod must be running)
make clean          - reverts everything to its original state
endef
