# To Do

## refactor core

* move state from memory to disk, sqlite probably
* allows us to retain stats etc over restart
* simplifies code
* keep only running nodes in memory
* negligible I/O cost, as majority is I/O wait getting config

## separate login to own package

* oxidized-script is not only use-case
* it would be good to have minimal package used to login to routers
* oxidized just one consumer of that functionality
* what to do with models, we need model to know how to login. Should models be separated to another package? oxidized-core, oxidized-models and oxidized-login?
* how can we allow interactive login in oxidized-login? With functional VTY etc? REPL loop in input/ssh and input/telnet?

## thread number

* think about algo
* if job ended later than now-iteration have rand(node.size) == 0 to add thread
* if now is less than job_ended+iteration same chance to remove thread?
* should we try to avoid max threads from being hit? (like maybe non-success thread is pulling average?)

## docs, testing

* yard docs
* minitest tests
