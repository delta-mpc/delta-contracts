# 合约方法文档

## 合约事件

### TaskCreated

任务发布者新建任务时触发

params:

|name | type | description | 
|---  | ---  | --- |
| creator | string | 创建者的地址 | 
| taskId  | bytes32 | 生成的任务Id |
| dataSet | string | 数据集名称 | 
| creatorUrl | string | 创建任务的服务器url | 
| commitment | bytes32 | 任务训练代码的哈希（用于客户端校验任务训练代码）|

### RoundStart
任务发布者新建任务时触发
event RoundStart(bytes32 taskId,uint64 round);
|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |

### RoundEnd
任务发布者结束轮次时触发
event RoundEnd(bytes32 taskId,uint64 round);
|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |


### PartnerSelected
任务发布者结束轮次时触发
event PartnerSelected(bytes32 taskId,uint64 round,address[] addrs);
|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |
| addrs | address[] | 任务发布者选择的节点地址 |


### AggregateStarted
开始安全聚合时触发
event AggregatStarted(bytes32 taskId,uint64 round,address[] addrs);
|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |
| addrs | address[] | 还在线的节点地址 |

### CalculateStarted
任务发布者决定开始计算梯度时触发
event CalculateStarted(bytes32 taskId,uint64 round,address[] addrs);

|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |
| addrs | address[] | 已完成secret sharing 的计算节点 |

### ContentUploaded
计算节点上传内容时触发
event ContentUploaded(bytes32 taskId,uint64 round,address owner,address sharer,string contentType,bytes content);

|name | type | description | 
| --- | ---  | --- |
| taskId | string | 任务Id|
| round | uint64 | 轮次 |
| owner | address | 秘密分享的地址 |
| sharer | address | 秘密分享的对象地址 |
| contentType | string | 上传的类型 | 
| content | bytes | 上传的内容 | 

## 合约函数

### createTask

新建一个任务，并通过事件通知所有节点有新任务创建


params：

| name | type | description |
| --- | --- | --- |
| creatorUrl | string | 创建任务的服务器url |
| dataset | string | 任务所需要的数据库名称 |
| commitment | bytes32 | 任务训练代码的哈希（用于客户端校验任务训练代码） |

events:

[TaskCreated](#TaskCreated)

### startRound

开启任务的新一轮计算，并通过事件通知所有节点，任务开启了新一轮训练，可以等待节点加入这轮训练。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |

events:

[RoundStart](#RoundStart)


### selectCandidates

选择加入本轮训练的客户端，并结束本轮训练的选择阶段。通过事件广播被选中的客户端地址列表。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| clients | address[] | 被选中的客户端的地址列表 |

events:

[PartnerSelected](#PartnerSelected)

### startCalculate

开始计算阶段，并结束本轮训练的秘密分享阶段。通过事件广播上传过秘密分享的客户端地址列表。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| clients | address[] | 上传过秘密分享的客户端地址列表 |

events:

[CalculateStarted](#CalculateStarted)

### getResultCommitment

计算阶段，获取客户端上传的结果的哈希。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| client | address | 目标客户端 |

returns:

| name | type | description |
| --- | --- | --- |
| commitment | bytes | 目标客户端结果的哈希 |


### startAggregate

开始聚合阶段，并结束本轮训练的计算阶段。通过事件广播上传了结果的客户端地址列表。
 
params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| clients | address[] | 上传了结果的客户端地址列表 |

events:

[AggregateStarted](#AggregateStarted)

### getSecretSharingData

聚合阶段，获取在线客户端的随机种子的秘密分享片段及哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| owner | address | 随机种子的拥有者 |
| sharee | address | 秘密分享的目标 |

returns:

| name | type | description |
| --- | --- | --- |
| ssSeed | bytes | 随机种子的秘密分享片段 |
| ssSeedCmmtmnt | bytes | 随机种子的秘密分享片段哈希 |
| ssSecretKey | bytes | SK2的秘密分享片段 |
| ssSecretKeyMaskCmmtmnt | bytes | SK2的秘密分享片段哈希 |


### joinRound

加入某个任务的某一轮训练，如果加入成功则通过事件通知所有节点，调用者加入了某个任务的某一轮训练。

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| pk1 | bytes32 | 公钥，用于客户端之间生成加密信道 |
| pk2 | bytes32 | 公钥，用于生成加密结果的mask |


### getClientPublickeys

获取某客户端上传的公钥PK1和PK2。

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| candidateAddr | address | 客户端地址 |

returns:

| name | type | description |
| --- | --- | --- |
| pks | tuple[bytes32, bytes32] | pk1和pk2 |


### uploadSeedCommitment

上传加密Mask的随机种子的秘密分享片段的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address| 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |
| seedCommitment | bytes | 随机种子的哈希 |

events:
[ContentUploaded](#ContentUploaded)(任务ID,轮次，随机种子的拥有者，秘密分享的目标，"SEEDCMMT",随机种子的哈希)

### uploadSecretKeyCommitment

上传SK2的秘密分享片段的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address| 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |
| skCommitment | bytes | SK2的哈希 |

events:
[ContentUploaded](#ContentUploaded)(任务ID,轮次，随机种子的拥有者，秘密分享的目标，"SKMASKCMMT",SK2的哈希)

### uploadResultCommitment

上传本轮训练结果（权重或梯度）的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| commitment | bytes | 本轮训练结果（权重或梯度）的哈希 |

events:
[ContentUploaded](#ContentUploaded)(任务ID,轮次，上传者，null，"WEIGHT",本轮训练结果（权重或梯度）的哈希)

### uploadSeed

聚合阶段，上传在线客户端的加密Mask的随机种子的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| sharee | address | 秘密分享的目标 | 
| seed | bytes | 随机种子的秘密分享片段 |

events:
[ContentUploaded](#ContentUploaded)(任务ID,轮次,Seed的拥有者（在线的客户端）,秘密分享的目标，"SEED",随机种子的秘密分享片段)

### uploadSecretkeyMask

聚合阶段，上传离线客户端的SK2的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address | SK2的拥有者（离线的客户端） | 
| skmask | bytes | SK2的秘密分享片段 |

events:
[ContentUploaded](#ContentUploaded)(任务ID,轮次,SK2的拥有者（离线的客户端）,秘密分享的目标（调用者），"SKMASK",SK2的秘密分享片段)

### endRound

结束本轮训练

params:

| name | type | description |
| --- | --- | --- |
| taskId | bytes32 | 任务ID |
| round | uint64 | 轮次 |

events:
[RoundEnd](#RoundEnd)(任务ID,轮次)