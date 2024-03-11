# Make sure these targets always run
.PHONY: help rights clean-rights

help:
	@: $(info $(HELP))

rights:
	podman unshare chown -R 30000:30000 oxidized-config oxidized-ssh

clean-rights:
	podman unshare chown -R 0:0 *

start: rights model-image
	podman-compose -p oxidized up

run: start

stop:
	podman-compose -p oxidized down
	$(MAKE) clean-rights

start-local:
	if [ -f oxidized-config/config.local ]; then \
	  cp oxidized-config/config.local oxidized-config/config; \
	else \
	  echo "oxidized-config/config.local does not exist"; \
	fi
	$(MAKE) start

stop-local: stop
	if [ -f oxidized-config/config.local ]; then \
	  git checkout -- oxidized-config/config; \
	else \
	  echo "oxidized-config/config.local does not exist"; \
	fi

model-image:
	podman image exists localhost/local/model || \
	  podman build -t local/model -f model-simulation/Dockerfile-model .

model-clean:
	podman rmi local/model

clean: stop-local model-clean

define HELP
make help           - This help
make rights         - Change the rights of mapped folders for user oxidized
                      in the container
make clean-rights   - Revert the rights of mapped folders to the local user
make start          - Start the containter
                      You can interrupt with Ctrl-C, but make sure you run
                      make stop to realy stop the container
make run            - Same as make start
make stop           - Stop the containter
make start-local    - Starts the container with the local configuration config.local
make stop-local     - Stops the container and restores oxidized-config/config from git
make model-image    - Creates a local OCI-Image to run simulated devices
make model-clean    - Removes the local OCI-Image to run simulated devices
make clean          - make stop-local + model-clean
endef
