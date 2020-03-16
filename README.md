![grants_badge](./grants_badge.png)

# scale.rb

**Ruby SCALE Codec Library and Substrate Json-rpc Api Client.**

SCALE is a lightweight, efficient, binary serialization and deserialization codec used by substrate. Most of the input and output data of the substrate API are encoded in SCALE data format. 

This is a SCALE codec library and substrate json-rpc api client implemented in ruby language for general use. It contains the implementation of low-level data formats, various substrate types, metadata support and json-rpc client.

This work is the prerequisite of our subsequent series of projects. We hope to familiarize and quickly access Polkadot and Substrate through ruby. We plan to develop the back end of our applications in ruby language, and then interact with nodes or synchronize data through this library.

Please refer to the [official doc](https://substrate.dev/docs/en/overview/low-level-data-format) for more details about SCALE low-level data format.

Because the feature of ruby 2.6 is used, the ruby version is required to be >= 2.6. it will be compatible with older ruby versions when released.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scale.rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scale

## Usage

1. decode

```ruby
require "scale"

# decode a compact integer
scale_bytes = Scale::Bytes.new("0x1501") # create scale_bytes object from scale encoded hex string
o = Scale::Types::Compact.decode(scale_bytes) # use scale type to decode scale_bytes object
p o.value # 69
```

2. encode

```ruby
require "scale"

o = Scale::Types::Compact.new(69)
p o.encode # "1501"
```
Please go to `spec` dir for more examples.

## Command line tools

After install scale.rb gem, there is a command named `scale` available. You can use it directly in your terminal.

```bash
> scale
Commands:
  scale decode TYPE_NAME HEX CHAIN_SPEC  # decode HEX string using TYPE_NAME
  scale help [COMMAND]                   # Describe available commands or one specific command
  scale specs                            # list all chain specs
  scale type TYPE_NAME CHAIN_SPEC        # show type's ruby class
  scale types CHAIN_SPEC                 # list all types implemented for chain
```

```bash
> scale decode Compact 0x0300000040
#<Scale::Types::Compact:0x00007f951c21fd00 @value=1073741824>
```

```bash
> scale specs
robonomics, darwinia, kusama-cc2, kusama-cc3, westend, test, centrifuge, kulupu, edgeware, plasm, joystream, default, acala, kusama
```

```bash
> scale types kusama
String, Address, Hash, Compact, Metadata, Bool, U8, U16, U32, U64, U128, MetadataModule, 
...
```

```bash
> scale type AuthoritySignature
Scale::Types::H512
```

```bash
> scale type "(AccountId, Balance)"
Scale::Types::Struct_Of_AccountId_Balance
```

## Types supported

You can use the command line tool to list all types supported by scale.rb.

First, get supported chain spec:

```bash
> scale specs
robonomics, darwinia, kusama-cc2, kusama-cc3, westend, test, centrifuge, kulupu, edgeware, plasm, joystream, default, acala, kusama
```

Then, list types. if no chain spec specified, the default spec is used:

```bash
> scale types
ValidatorPrefsLegacy, String, Hash, Address, Compact, Bool, U8, U16, U32, U64, U128, Metadata, Hex, H160, H256, H512, MetadataModule, AccountId, Balance, BalanceOf, BlockNumber, AccountIndex, Era, EraIndex, Moment, CompactMoment, ProposalPreimage, MetadataModuleCall, MetadataModuleCallArgument, MetadataModuleEvent, MetadataModuleStorage, RewardDestination, WithdrawReasons, MetadataV3, ReferendumIndex, PropIndex, Vote, SessionKey, SessionIndex, ParaId, KeyValue, NewAccountOutcome, StakingLedger, MetadataV7ModuleStorageEntry, MetadataV7Module, UnlockChunk, MetadataV7, Exposure, MetadataV7ModuleConstants, IndividualExposure, MetadataV8, Bytes, BabeAuthorityWeight, Points, EraPoints, VoteThreshold, Null, InherentOfflineReport, LockPeriods, VoteIndex, ProposalIndex, Permill, Perbill, ApprovalFlag, SetIndex, AuthorityId, ValidatorId, AuthorityWeight, StoredPendingChange, MetadataV10, ReportIdOf, StorageHasher, VoterInfo, MetadataV9, MetadataV7ModuleStorage, Gas, CodeHash, PrefabWasmModule, OpaqueNetworkState, OpaquePeerId, OpaqueMultiaddr, SessionKeysSubstrate, LegacyKeys, EdgewareKeys, QueuedKeys, LegacyQueuedKeys, EdgewareQueuedKeys, VecU8Length2, VecU8Length3, VecQueuedKeys, VecU8Length8, VecU8Length16, VecU8Length4, VecU8Length20, VecU8Length32, VecU8Length64, BalanceLock, EthereumAddress, EcdsaSignature, Bidder, BlockAttestations, IncludedBlocks, MetadataV8Module, MetadataModuleError, HeadData, Conviction, EraRewards, SlashJournalEntry, UpwardMessage, ParachainDispatchOrigin, StoredState, Votes, WinningDataEntry, IdentityType, VoteType, VoteOutcome, Identity, ProposalTitle, ProposalContents, ProposalStage, ProposalCategory, VoteStage, TallyType, Attestation, VecNextAuthority, BoxProposal, (AccountId, Balance), AccountData, CandidateReceipt, AttestedCandidate, LockIdentifier, FullIdentification, IdentificationTuple, SetId, Reasons, RoundNumber, AuctionIndex, AuthIndex, AuthorityIndex, Signature, CollatorSignature, NextAuthority, AuthorityList, BalanceUpload, CollatorId, ContractInfo, TrieId, RawAliveContractInfo, DispatchClass, DispatchInfo, EgressQueueRoot, EventIndex, Extrinsic, IdentityFields, IdentityInfoAdditional, IdentityInfo, Judgement, Judgement<BalanceOf>, LeasePeriod, LeasePeriodOf, (LeasePeriodOf, IncomingParachain<AccountId, Hash>), (ParaId, Option<(CollatorId, Retriable)>), MaybeVrf, MemberCount, MomentOf, MoreAttestations, Multiplier, Timepoint, Multisig, Offender, PhantomData, sp_std::marker::PhantomData<(AccountId, Event)>, Reporter, OffenceDetails<AccountId, IdentificationTuple>, OpenTipFinder, OpenTipTip, OpenTip<AccountId, BalanceOf, BlockNumber, Hash>, ParaIdOf, ParaScheduling, ParaInfo, Percent, SlotNumber, VrfData, VrfProof, RawAuraPreDigest, RawBabePreDigest, RawBabePreDigestPrimary, RawBabePreDigestSecondary, ReferendumInfo<BlockNumber, Proposal>, (ReferendumInfo<BlockNumber, Proposal>), ReferendumInfo<BlockNumber, Hash>, (ReferendumInfo<BlockNumber, Hash>), RegistrarIndex, RegistrarInfo, Registration, RegistrationJudgement, Schedule, StakingLedger<AccountId, BalanceOf>, SubId, UncleEntryItem<BlockNumber, Hash, AccountId>, VestingSchedule<Balance, BlockNumber>, Weight, WeightMultiplier, WinningData, Index, Kind, Nominations, OpaqueTimeSlot, Box<<T as Trait<I>>::Proposal>, AuthoritySignature, <AuthorityId as RuntimeAppPublic>::Signature, &[u8], Forcing, Heartbeat, ChangesTrieConfiguration, ConsensusEngineId, DigestItem, Digest, DigestOf, SpanIndex, slashing::SpanIndex, SlashingSpans, slashing::SlashingSpans, SpanRecord, slashing::SpanRecord<BalanceOf>, UnappliedSlashOther, UnappliedSlash<AccountId, BalanceOf>, Keys, Header, DispatchErrorModule, DispatchError, DispatchResult, ActiveRecovery, RecoveryConfig, BidKindVouch, BidKind, Bid, StrikeCount, VouchingStatus, ExtrinsicMetadata
```

chain spec:

```bash
> scale types kusama
ValidatorPrefsLegacy, String, Hash, Address, Compact, Bool, U8, U16, U32, U64, U128, Metadata, Hex, H160, H256, H512, MetadataModule, AccountId, Balance, BalanceOf, BlockNumber, AccountIndex, Era, EraIndex, Moment, CompactMoment, ProposalPreimage, MetadataModuleCall, MetadataModuleCallArgument, MetadataModuleEvent, MetadataModuleStorage, RewardDestination, WithdrawReasons, MetadataV3, ReferendumIndex, PropIndex, Vote, SessionKey, SessionIndex, ParaId, KeyValue, NewAccountOutcome, StakingLedger, MetadataV7ModuleStorageEntry, MetadataV7Module, UnlockChunk, MetadataV7, Exposure, MetadataV7ModuleConstants, IndividualExposure, MetadataV8, Bytes, BabeAuthorityWeight, Points, EraPoints, VoteThreshold, Null, InherentOfflineReport, LockPeriods, VoteIndex, ProposalIndex, Permill, Perbill, ApprovalFlag, SetIndex, AuthorityId, ValidatorId, AuthorityWeight, StoredPendingChange, MetadataV10, ReportIdOf, StorageHasher, VoterInfo, MetadataV9, MetadataV7ModuleStorage, Gas, CodeHash, PrefabWasmModule, OpaqueNetworkState, OpaquePeerId, OpaqueMultiaddr, SessionKeysSubstrate, LegacyKeys, EdgewareKeys, QueuedKeys, LegacyQueuedKeys, EdgewareQueuedKeys, VecU8Length2, VecU8Length3, VecQueuedKeys, VecU8Length8, VecU8Length16, VecU8Length4, VecU8Length20, VecU8Length32, VecU8Length64, BalanceLock, EthereumAddress, EcdsaSignature, Bidder, BlockAttestations, IncludedBlocks, MetadataV8Module, MetadataModuleError, HeadData, Conviction, EraRewards, SlashJournalEntry, UpwardMessage, ParachainDispatchOrigin, StoredState, Votes, WinningDataEntry, IdentityType, VoteType, VoteOutcome, Identity, ProposalTitle, ProposalContents, ProposalStage, ProposalCategory, VoteStage, TallyType, Attestation, VecNextAuthority, BoxProposal, (AccountId, Balance), AccountData, CandidateReceipt, AttestedCandidate, LockIdentifier, FullIdentification, IdentificationTuple, SetId, Reasons, RoundNumber, AuctionIndex, AuthIndex, AuthorityIndex, Signature, CollatorSignature, NextAuthority, AuthorityList, BalanceUpload, CollatorId, ContractInfo, TrieId, RawAliveContractInfo, DispatchClass, DispatchInfo, EgressQueueRoot, EventIndex, Extrinsic, IdentityFields, IdentityInfoAdditional, IdentityInfo, Judgement, Judgement<BalanceOf>, LeasePeriod, LeasePeriodOf, (LeasePeriodOf, IncomingParachain<AccountId, Hash>), (ParaId, Option<(CollatorId, Retriable)>), MaybeVrf, MemberCount, MomentOf, MoreAttestations, Multiplier, Timepoint, Multisig, Offender, PhantomData, sp_std::marker::PhantomData<(AccountId, Event)>, Reporter, OffenceDetails<AccountId, IdentificationTuple>, OpenTipFinder, OpenTipTip, OpenTip<AccountId, BalanceOf, BlockNumber, Hash>, ParaIdOf, ParaScheduling, ParaInfo, Percent, SlotNumber, VrfData, VrfProof, RawAuraPreDigest, RawBabePreDigest, RawBabePreDigestPrimary, RawBabePreDigestSecondary, ReferendumInfo<BlockNumber, Proposal>, (ReferendumInfo<BlockNumber, Proposal>), ReferendumInfo<BlockNumber, Hash>, (ReferendumInfo<BlockNumber, Hash>), RegistrarIndex, RegistrarInfo, Registration, RegistrationJudgement, Schedule, StakingLedger<AccountId, BalanceOf>, SubId, UncleEntryItem<BlockNumber, Hash, AccountId>, VestingSchedule<Balance, BlockNumber>, Weight, WeightMultiplier, WinningData, Index, Kind, Nominations, OpaqueTimeSlot, Box<<T as Trait<I>>::Proposal>, AuthoritySignature, <AuthorityId as RuntimeAppPublic>::Signature, &[u8], Forcing, Heartbeat, ChangesTrieConfiguration, ConsensusEngineId, DigestItem, Digest, DigestOf, SpanIndex, slashing::SpanIndex, SlashingSpans, slashing::SlashingSpans, SpanRecord, slashing::SpanRecord<BalanceOf>, UnappliedSlashOther, UnappliedSlash<AccountId, BalanceOf>, Keys, Header, DispatchErrorModule, DispatchError, DispatchResult, ActiveRecovery, RecoveryConfig, BidKindVouch, BidKind, Bid, StrikeCount, VouchingStatus, ExtrinsicMetadata, SessionKeysPolkadot
```

## Running tests

1. Download or clone the code to local, and enter the code root directory
2. If rust is installed on your system (for instance, `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`), call `make` to build the FFI library
3. Run all tests

```
rspec
```

To run only low level format tests, call

```
rspec spec/low_level_spec.rb
```


## Docker

1. update to latest image

   `docker pull itering/scale`

2. Run image:

   `docker run -it itering/scale`

   This  will enter the container with a linux shell opened. 

   ```shell
   /usr/src/app # 
   ```

3. Type `rspec` to run all tests

   ```shell
   /usr/src/app # rspec
   ...................
   
   Finished in 0.00883 seconds (files took 0.09656 seconds to load)
   19 examples, 0 failures
   ```

4. Or type `./bin/console` to enter the ruby interactive environment and run any decode or encode code

   ```shell
   /usr/src/app # ./bin/console
   [1] pry(main)> scale_bytes = Scale::Bytes.new("0x1501")
   => #<Scale::Bytes:0x000055daa883ba70 @bytes=[21, 1], @data="0x1501", @offset=0>
   [2] pry(main)> o = Scale::Types::Compact.decode(scale_bytes)
   => #<Scale::Types::Compact:0x000055daa89b0db0 @value=69>
   [3] pry(main)> p o.value
   69
   => 69
   [4] pry(main)>
   ```


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/itering/scale.rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
