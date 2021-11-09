# 身份合约方法文档

## 合约函数

### join

节点加入任务网络

params: 

| name | type | description |
| --- | --- | --- |
| url | string | 服务器的url |
| name | string | 节点的显示名称 |

### updateUrl

更新节点的url

params: 

| name | type | description |
| --- | --- | --- |
| url | string | 服务器新的url |

### updateName

更新节点的名称

params: 

| name | type | description |
| --- | --- | --- |
| name | string | 节点新的显示名称 |

### leave

节点退出任务网络

params:

None

### getNodeInfo

通过节点地址获取节点信息

params: 

| name | type | description |
| --- | --- | --- |
| address | address | 节点的地址 |

returns：

| name | type | description |
| --- | --- | --- |
| info | tuple[string, string ] | url和name |

