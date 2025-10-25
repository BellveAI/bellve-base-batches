/* tslint:disable */
/* eslint-disable */

import 'reflect-metadata';
import { DatabaseSchema } from '@sentio/sdk/core';
import { Column, Entity, IDColumn, TimestampColumn, AbstractEntity } from '@sentio/sdk/store';

@Entity('DepositRequestEntity')
class DepositRequestEntity extends AbstractEntity {
  @IDColumn
  id!: string;  // depositHash

  @Column('String!')
  user!: string;

  @Column('String!')
  token!: string;

  @Column('String!')
  amount!: string;

  @Column('String!')
  minUnitsOut!: string;

  @Column('Int!')
  batchWindow!: number;

  @Column('Int!')
  blockNumber!: number;

  @TimestampColumn
  timestamp!: Date;

  @Column('Boolean!')
  resolved!: boolean;

  @Column('Int!')
  riskProfile!: number;
}

@Entity('WithdrawalRequestEntity')
class WithdrawalRequestEntity extends AbstractEntity {
  @IDColumn
  id!: string;  // withdrawalHash

  @Column('String!')
  user!: string;

  @Column('String!')
  token!: string;

  @Column('String!')
  shares!: string;

  @Column('String!')
  minTokensOut!: string;

  @Column('Int!')
  batchWindow!: number;

  @Column('Int!')
  blockNumber!: number;

  @TimestampColumn
  timestamp!: Date;

  @Column('Boolean!')
  resolved!: boolean;

  @Column('Int!')
  riskProfile!: number;
}

@Entity('BatchDepositEntity')
class BatchDepositEntity extends AbstractEntity {
  @IDColumn
  id!: string;  // batchWindow-batchHash

  @Column('Int!')
  batchWindow!: number;

  @Column('String!')
  totalAmount!: string;

  @Column('Int!')
  depositCount!: number;

  @Column('Int!')
  blockNumber!: number;

  @TimestampColumn
  timestamp!: Date;

  @Column('Boolean!')
  resolved!: boolean;
}

@Entity('BatchWithdrawalEntity')
class BatchWithdrawalEntity extends AbstractEntity {
  @IDColumn
  id!: string;  // batchWindow-batchHash

  @Column('Int!')
  batchWindow!: number;

  @Column('String!')
  totalShares!: string;

  @Column('Int!')
  withdrawalCount!: number;

  @Column('Int!')
  blockNumber!: number;

  @TimestampColumn
  timestamp!: Date;

  @Column('Boolean!')
  resolved!: boolean;
}

@Entity('AccountNFTStateEntity')
class AccountNFTStateEntity extends AbstractEntity {
  @IDColumn
  id!: string;  // user-riskProfile

  @Column('String!')
  user!: string;

  @Column('Int!')
  riskProfile!: number;

  @Column('String!')
  balance!: string;

  @Column('String!')
  pendingDeposit!: string;

  @Column('String!')
  pendingWithdrawal!: string;

  @Column('Int!')
  blockNumber!: number;

  @TimestampColumn
  timestamp!: Date;
}

const source = `
  type DepositRequestEntity @entity {
    id: ID!
    user: String!
    token: String!
    amount: String!
    minUnitsOut: String!
    batchWindow: Int!
    blockNumber: Int!
    timestamp: Timestamp!
    resolved: Boolean!
    riskProfile: Int!
  }

  type WithdrawalRequestEntity @entity {
    id: ID!
    user: String!
    token: String!
    shares: String!
    minTokensOut: String!
    batchWindow: Int!
    blockNumber: Int!
    timestamp: Timestamp!
    resolved: Boolean!
    riskProfile: Int!
  }

  type BatchDepositEntity @entity {
    id: ID!
    batchWindow: Int!
    totalAmount: String!
    depositCount: Int!
    blockNumber: Int!
    timestamp: Timestamp!
    resolved: Boolean!
  }

  type BatchWithdrawalEntity @entity {
    id: ID!
    batchWindow: Int!
    totalShares: String!
    withdrawalCount: Int!
    blockNumber: Int!
    timestamp: Timestamp!
    resolved: Boolean!
  }

  type AccountNFTStateEntity @entity {
    id: ID!
    user: String!
    riskProfile: Int!
    balance: String!
    pendingDeposit: String!
    pendingWithdrawal: String!
    blockNumber: Int!
    timestamp: Timestamp!
  }
`;

DatabaseSchema.register({
  source,
  entities: {
    DepositRequestEntity,
    WithdrawalRequestEntity,
    BatchDepositEntity,
    BatchWithdrawalEntity,
    AccountNFTStateEntity,
  },
});

export {
  DepositRequestEntity,
  WithdrawalRequestEntity,
  BatchDepositEntity,
  BatchWithdrawalEntity,
  AccountNFTStateEntity,
};

