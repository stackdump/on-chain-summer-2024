Jetsam
------

On Chain Summer 2024 hackathon project (incomplete).

The idea for this project is a 'crafting-while-falling' gameplay experience where crafting happens on-chain.

Here's some AI-generated concepts for sprite sheets

![Screenshot 2024-07-01 at 9 14 41 AM](https://github.com/stackdump/on-chain-summer-2024/assets/243500/ee0dc148-2996-47bb-8de4-f74121bc8722)

![Screenshot 2024-07-01 at 9 16 28 AM](https://github.com/stackdump/on-chain-summer-2024/assets/243500/72af6746-2d94-4558-9354-3eaaefc44c9a)

The crafting tree is somewhat represented below. Check out `/hardhat/contracts/Jetsam.sol` to see the current WIP (incomplete).

![Screenshot 2024-07-01 at 9 16 43 AM](https://github.com/stackdump/on-chain-summer-2024/assets/243500/ab3e0b0e-b1ec-43af-9540-83bf17ea0eaf)


TakeAways
---------

- not every hosted node can keep up w/ block syncs every 60s
- re: pflow.xyz generated code - TODO: re-think templates w/ Libraries to support larger state machines
- pg_cron + pg_net from supabase postgres node worked out well, auto-syncing db every 1m
- generating the Golang data types from .Sol makes interfacting w/ on-chain metamodels much easier
- Same for TS-chain usage w/ hardhat to get contract types

  
What's Here?
------------

The Actual game implementation in phaser.js is completely missing.
During hackathon works was done mostly on DB syncing w/ chain and smart contract model for crafting.

TODO
----
- make pflow.xyz generate better solidity for larger model definitions
- refine the DB sync useage to process meaningful data from contract event logs
- actually build the game
- refine existing sample smarrt contract to support storing state-per-addess
