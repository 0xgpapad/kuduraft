// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
// Protobufs which are common throughout Kudu.
//
// This file may contain protobufs which are persisted on disk
// as well as sent on the wire. If a particular protobuf is only
// used as part of the client-server wire protocol, it should go
// in common/wire_protocol.proto instead. If it is only used within
// the server(s), it should go in cfile/cfile.proto, server/metadata.proto,
// etc, as appropriate.

// **************   NOTICE  *******************************************
// Facebook 2019 - Notice of Changes
// This file has been modified to extract only the Raft implementation
// out of Kudu into a fork known as kuduraft.
// ********************************************************************

namespace cpp2 facebook.raft
namespace py3 facebook.py3

// If you add a new type keep in mind to add it to the end
// or update AddMapping() functions like the one in key_encoder.cc
// that have a vector that maps the protobuf tag with the index.
enum DataType {
  UNKNOWN_DATA = 999,
  UINT8 = 0,
  INT8 = 1,
  UINT16 = 2,
  INT16 = 3,
  UINT32 = 4,
  INT32 = 5,
  UINT64 = 6,
  INT64 = 7,
  STRING = 8,
  BOOL = 9,
  FLOAT = 10,
  DOUBLE = 11,
  BINARY = 12,
  UNIXTIME_MICROS = 13,
  INT128 = 14,
  DECIMAL32 = 15,
  DECIMAL64 = 16,
  DECIMAL128 = 17,
  IS_DELETED = 18, // virtual column; not a real data type
}

enum EncodingType {
  UNKNOWN_ENCODING = 999,
  AUTO_ENCODING = 0,
  PLAIN_ENCODING = 1,
  PREFIX_ENCODING = 2,
  // GROUP_VARINT encoding is deprecated and no longer implemented.
  GROUP_VARINT = 3,
  RLE = 4,
  DICT_ENCODING = 5,
  BIT_SHUFFLE = 6,
}

/*
  FB_DO_NOT_REMOVE

enum HmsMode {
  NONE = 0;
  ENABLE_HIVE_METASTORE = 1;
  ENABLE_METASTORE_INTEGRATION = 2;
};

// Holds detailed attributes for the column. Only certain fields will be set,
// depending on the type of the column.
message ColumnTypeAttributesPB {
  // For decimal columns
  optional int32 precision = 1;
  optional int32 scale = 2;
}

// TODO: Differentiate between the schema attributes
// that are only relevant to the server (e.g.,
// encoding and compression) and those that also
// matter to the client.
message ColumnSchemaPB {
  optional uint32 id = 1;
  required string name = 2;
  required DataType type = 3;
  optional bool is_key = 4 [default = false];
  optional bool is_nullable = 5 [default = false];

  // Default values.
  // NOTE: as far as clients are concerned, there is only one
  // "default value" of a column. The read/write defaults are used
  // internally and should not be exposed by any public client APIs.
  //
  // When passing schemas to the master for create/alter table,
  // specify the default in 'read_default_value'.
  //
  // Contrary to this, when the client opens a table, it will receive
  // both the read and write defaults, but the *write* default is
  // what should be exposed as the "current" default.
  optional bytes read_default_value = 6;
  optional bytes write_default_value = 7;

  // The following attributes refer to the on-disk storage of the column.
  // They won't always be set, depending on context.
  optional EncodingType encoding = 8 [default=AUTO_ENCODING];
  optional CompressionType compression = 9 [default=DEFAULT_COMPRESSION];
  optional int32 cfile_block_size = 10 [default=0];

  optional ColumnTypeAttributesPB type_attributes = 11;
}

message ColumnSchemaDeltaPB {
  optional string name = 1;
  optional string new_name = 2;

  optional bytes default_value = 4;
  optional bool remove_default = 5;

  optional EncodingType encoding = 6;
  optional CompressionType compression = 7;
  optional int32 block_size = 8;
}

message SchemaPB {
  repeated ColumnSchemaPB columns = 1;
}

*/

struct HostPort {
  1: string host = "unknown";
  2: i32 port = -1;
}

// The external consistency mode for client requests.
// This defines how transactions and/or sequences of operations that touch
// several TabletServers, in different machines, can be observed by external
// clients.
//
// Note that ExternalConsistencyMode makes no guarantee on atomicity, i.e.
// no sequence of operations is made atomic (or transactional) just because
// an external consistency mode is set.
// Note also that ExternalConsistencyMode has no implication on the
// consistency between replicas of the same tablet.
enum ExternalConsistencyMode {
  UNKNOWN_EXTERNAL_CONSISTENCY_MODE = 0,

  // The response to any write will contain a timestamp.
  // Any further calls from the same client to other servers will update
  // those servers with that timestamp. The user will make sure that the
  // timestamp is propagated through back-channels to other
  // KuduClient's.
  //
  // WARNING: Failure to propagate timestamp information through
  // back-channels will negate any external consistency guarantee under this
  // mode.
  //
  // Example:
  // 1 - Client A executes operation X in Tablet A
  // 2 - Afterwards, Client A executes operation Y in Tablet B
  //
  //
  // Client B may observe the following operation sequences:
  // {}, {X}, {X Y}
  //
  // This is the default mode.
  CLIENT_PROPAGATED = 1,

  // The server will guarantee that each transaction is externally
  // consistent by making sure that none of its results are visible
  // until every Kudu server agrees that the transaction is in the past.
  // The client is not obligated to forward timestamp information
  // through back-channels.
  //
  // WARNING: Depending on the clock synchronization state of TabletServers
  // this may imply considerable latency. Moreover operations with
  // COMMIT_WAIT requested external consistency will outright fail if
  // TabletServer clocks are either unsynchronized or synchronized but
  // with a maximum error which surpasses a pre-configured one.
  //
  // Example:
  // - Client A executes operation X in Tablet A
  // - Afterwards, Client A executes operation Y in Tablet B
  //
  //
  // Client B may observe the following operation sequences:
  // {}, {X}, {X Y}
  COMMIT_WAIT = 2,
}