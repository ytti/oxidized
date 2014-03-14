# thread number
  * think about algo
  * if job ended later than now-iteration have rand(node.size) == 0 to add thread
  * if now is less than job_ended+iteration same chance to remove thread?
  * should we try to avoid max threads from being hit? (like maybe non-success thread is pulling average?)

# config
  * save keys as strings, load as symbols?

# other 
should it offer cli mass config-pusher? (I think not, I have ideas for such
program and I'm not sure if synergies are high enough for shared code without
making both bit awkward)

use sidekiq? Any benefits?


# docs, testing
  * yard docs
  * rspec tests
