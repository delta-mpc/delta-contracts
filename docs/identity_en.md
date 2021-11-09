# Identity Contract Document

## Contract Methods

### join

Node join in the task network.

params: 

| name | type | description |
| --- | --- | --- |
| url | string | node server url |
| name | string | node display name |

### updateUrl

Update node server url

params: 

| name | type | description |
| --- | --- | --- |
| url | string | server url |

### updateName

Update node display name 

params: 

| name | type | description |
| --- | --- | --- |
| name | string | node display name |

### leave

Node leave the task network

params:

None

### getNodeInfo

Get node information by node address.

params: 

| name | type | description |
| --- | --- | --- |
| address | address | node address |

returns：

| name | type | description |
| --- | --- | --- |
| info | tuple[string, string ] | url and name |

