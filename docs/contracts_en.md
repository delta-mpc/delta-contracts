# Horizontal Federated Learning Contract Document

## Contract Methods

### createTask

Create a new task and then notify all participants 

params：

| name | type | description |
| --- | --- | --- |
| dataset | string | the dataset name for this computation task |
| commitment | bytes32 | hash of the training code (for client validation purpose)|

events:

[TaskCreated](#TaskCreated)

### startRound

Start a new round and then notify all participants , waiting for them to join.

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round|

events:

[RoundStarted](#RoundStarted)


### selectCandidates

Choose clients to participate in this round and close the selecting phase of this round.
The address of those who is chosen will be broadcasted via events


params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| clients | address[] | the chosen addresses |

events:

[PartnerSelected](#PartnerSelected)


### startCalculate

Start calculating phase and at the same time close the secret sharing phase. 
The address of those who has done the secret sharing will be broadcasted via events

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| clients | address[] | the address of those clients who has finished secret sharing|

events:

[CalculateStarted](#CalculateStarted)


### getResultCommitment

Get the result commitment hash uploaded by clients


params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| client | address | the uploader of this commiment|

returns:

| name | type | description |
| --- | --- | --- |
| commitment | bytes | the hash of this commitment |


### startAggregate

start aggregating phase as well as ending calculating phase, broadcasting 
the address list of clients who has uploaded result.

 
params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round  |
| clients | address[] | the address list of clients who has uploaded result |

events:

[AggregateStarted](#AggregateStarted)


### getSecretSharingData

Get secret sharing data (seeds, secret key, commitments etc.)


params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| owner | address | the owner address |
| sharee | address | the sharee address |

returns:

| name | type | description |
| --- | --- | --- |
| ssSeed | bytes | secret sharing piece of seed |
| ssSeedCmmtmnt | bytes | hash of ssSeed |
| ssSecretKey | bytes | secret sharing piece of secret key |
| ssSecretKeyMaskCmmtmnt | bytes | hash of ssSecretKey |


### joinRound

join a round of a task, notify all participants when join succeeded.


params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID|
| round | uint64 | the sequence number of round |
| pk1 | bytes32 | public key,used for secret channel establishment |
| pk2 | bytes32 | public key,used for generating cyphered mask |


### getClientPublickeys

get public keys of a client

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| candidateAddr | address | the client address |

returns:

| name | type | description |
| --- | --- | --- |
| pks | tuple[bytes32, bytes32] | pk1 & pk2 |


### uploadSeedCommitment

upload the hash of the seed used for generating cyphered mask


params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| owner | address| seed owner |
| sharee | address | seed sharee |
| seedCommitment | bytes | seed hash |

events:
[SeedCommitmentUploaded](#SeedCommitmentUploaded)

### uploadSecretKeyCommitment
upload sk2 hash


params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task id |
| round | uint64 | the sequence number of round |
| owner | address| secret key owner |
| sharee | address | secret key sharee |
| skCommitment | bytes | secret key hash |

events:
[SeedCommitmentUploaded](#SeedCommitmentUploaded)


### uploadResultCommitment

upload the result hash of this round (weights / gradients)


params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task id |
| round | uint64 | the sequence number of round |
| commitment | bytes | weights / gradients |

events:
[ResultUploaded](#ResultUploaded)


### uploadSeed

upload the online clients' piece of seed used for generating cyphered mask

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task id |
| round | uint64 | the sequence number of round |
| sharee | address | sharee address | 
| seed | bytes | seed to upload |

events:
[SeedUploaded](#SeedUploaded)


### uploadSecretkeyMask

upload piece of the sk2 of the offline clients

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task ID |
| round | uint64 | the sequence number of round |
| owner | address | owner of SK2 (must be an offline clients in this context) | 
| skMask | bytes | piece of SK2 |

events:
[SecretKeyUploaded](#SecretKeyUploaded)


### endRound

end this round

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | task id |
| round | uint64 | the sequence number of round |

events:
[RoundEnded](#RoundEnded)


## Contract Events

### TaskCreated

triggered upon creating new task

params:

|name | type | description | 
|---  | ---  | --- |
| address | address | address of node which create this task | 
| taskID  | bytes32 | task id |
| dataSet | string | dataset name | 
| url | string | server url of the node | 
| commitment | bytes32 | training code hash|

### RoundStarted
triggered upon starting a new round

event RoundStarted(bytes32 taskID,uint64 round);
|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | the sequence number of round |

### RoundEnded
triggered upon finishing round 

event RoundEnded(bytes32 taskID,uint64 round);
|name | type | description | 
| --- | ---  | --- |
| taskID | string | task id|
| round | uint64 | the sequence number of round |


### PartnerSelected
triggered upon task developer selecting candidates


event PartnerSelected(bytes32 taskID,uint64 round,address[] addrs);
|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | the sequence number of round |
| addrs | address[] | chosen addresses |


### AggregateStarted

triggered upon the inauguration of aggregating phase
event AggregatStarted(bytes32 taskID,uint64 round,address[] addrs);
|name | type | description | 
| --- | ---  | --- |
| taskID | string | task id|
| round | uint64 | the sequence number of round |
| addrs | address[] | online addresses |

### CalculateStarted

triggered upon the moment of task developer deciding to calculate gradients
event CalculateStarted(bytes32 taskID,uint64 round,address[] addrs);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task id|
| round | uint64 | the sequence number of round |
| addrs | address[] | computation nodes that has finished secret sharing |

### SeedUploaded
triggered upon seed uploading succeeded
event SeedUploaded(bytes32 taskID,uint64 round,address owner,address sharee,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | the sequence number of round |
| owner | address | owner address |
| sharee | address | sharee address |
| seed | bytes | seed | 


### SeedCommitmentUploaded
triggered upon seed commitment uploading succeeded

event SeedCommitmentUploaded(bytes32 taskID,uint64 round,address owner,address sharee,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | the sequence number of round |
| owner | address | owner address |
| sharee | address | sharee address  |
| content | bytes | seed hash | 


### SecretKeyCommitmentUploaded
triggered upon SecretKey commitment uploading succeeded

event SecretKeyCommitmentUploaded(bytes32 taskID,uint64 round,address owner,address sharee,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task id|
| round | uint64 | round number |
| owner | address | owner address |
| sharer | address | sharee address |
| content | bytes | sk2 hash | 


### SecretKeyUploaded
triggered upon SecretKey uploading succeeded

event SeedCommitmentUploaded(bytes32 taskID,uint64 round,address owner,address sharer,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | round number |
| owner | address | owner address |
| sharee | address | sharee address |
| content | bytes | sk2 | 


### ResultUploaded

triggered upon Result uploading succeeded
event ResultUploaded(bytes32 taskID,uint64 round,address owner,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskID | string | task ID|
| round | uint64 | round number |
| owner | address | owner address |
| content | bytes | result | 


