# 合约方法文档

## 服务端调用

### createTask

新建一个任务，并通过事件通知所有节点有新任务创建

params：

| name | type | description |
| --- | --- | --- |
| creatorUrl | string | 创建任务的服务器url |
| dataset | string | 任务所需要的数据库名称 |
| commitment | bytes32 | 任务训练代码的哈希（用于客户端校验任务训练代码） |

returns:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |

### startRound

开启任务的新一轮计算，并通过事件通知所有节点，任务开启了新一轮训练，可以等待节点加入这轮训练。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |

no returns

### selectCandidates

选择加入本轮训练的客户端，并结束本轮训练的选择阶段。通过事件广播被选中的客户端地址列表。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| clients | address[] | 被选中的客户端的地址列表 |

no returns

### startCalculate

开始计算阶段，并结束本轮训练的秘密分享阶段。通过事件广播上传过秘密分享的客户端地址列表。

params: 

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| clients | address[] | 上传过秘密分享的客户端地址列表 |

no returns

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

no returns

### getSeedPiece

聚合阶段，获取在线客户端的随机种子的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| owner | address | 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |

returns:

| name | type | description |
| --- | --- | --- |
| piece | bytes | 随机种子的秘密分享片段 |

### getSeedCommitment

聚合阶段，获取在线客户端的随机种子的秘密分享片段的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| owner | address | 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |

returns:

| name | type | description |
| --- | --- | --- |
| commitment | bytes | 随机种子的秘密分享片段的哈希 |

### getSKPiece

聚合阶段，获取离线客户端的SK2的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| owner | address | SK2的拥有者 |
| sharer | address | 秘密分享的目标 |

returns:

| name | type | description |
| --- | --- | --- |
| piece | bytes | SK2的秘密分享片段 |

### getSKCommitment

聚合阶段，获取离线客户端的SK2的秘密分享片段的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 开始的轮次 |
| owner | address | 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |

returns:

| name | type | description |
| --- | --- | --- |
| commitment | bytes | SK2的秘密分享片段的哈希 |



## 客户端调用

### joinRound

加入某个任务的某一轮训练，如果加入成功则通过事件通知所有节点，调用者加入了某个任务的某一轮训练。

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| pk1 | bytes32 | 公钥，用于客户端之间生成加密信道 |
| pk2 | bytes32 | 公钥，用于生成加密结果的mask |

returns:

| name | type | description |
| --- | --- | --- |
| success | bool | 是否加入成功 |


### getClientPKs

获取某客户端上传的公钥PK1和PK2。

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| client | address | 客户端地址 |

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
| commitment | bytes | 随机种子的哈希 |

no returns

### uploadSKCommitment

上传SK2的秘密分享片段的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address| 随机种子的拥有者 |
| sharer | address | 秘密分享的目标 |
| commitment | bytes | SK2的哈希 |

no returns

### uploadResultCommitment

上传本轮训练结果（权重或梯度）的哈希

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| commitment | bytes | 本轮训练结果（权重或梯度）的哈希 |

no returns

### uploadSeedPiece

聚合阶段，上传在线客户端的加密Mask的随机种子的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address | 随机种子的拥有者（在线的客户端） |
| piece | bytes | 随机种子的秘密分享片段 |

no returns

### uploadSKPiece

聚合阶段，上传离线客户端的SK2的秘密分享片段

params:

| name | type | description |
| --- | --- | --- |
| taskID | bytes32 | 任务ID |
| round | uint64 | 轮次 |
| owner | address | SK2的拥有者（离线的客户端） |
| piece | bytes | SK2的秘密分享片段 |


no returns
