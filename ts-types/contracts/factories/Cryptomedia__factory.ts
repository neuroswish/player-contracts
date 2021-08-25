/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { Cryptomedia, CryptomediaInterface } from "../Cryptomedia";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "buyer",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "poolBalance",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "totalSupply",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokens",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "price",
        type: "uint256",
      },
    ],
    name: "Buy",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "curator",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "layerCreator",
        type: "address",
      },
    ],
    name: "CurationAdded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "curator",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "layerCreator",
        type: "address",
      },
    ],
    name: "CurationRemoved",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "creator",
        type: "address",
      },
      {
        indexed: false,
        internalType: "string",
        name: "contentURI",
        type: "string",
      },
    ],
    name: "LayerAdded",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "creator",
        type: "address",
      },
    ],
    name: "LayerRemoved",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "seller",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "poolBalance",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "totalSupply",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokens",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "eth",
        type: "uint256",
      },
    ],
    name: "Sell",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_URI",
        type: "string",
      },
    ],
    name: "addLayer",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "addressToLayer",
    outputs: [
      {
        internalType: "address",
        name: "creator",
        type: "address",
      },
      {
        internalType: "string",
        name: "URI",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "bondingCurve",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_price",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_minTokensReturned",
        type: "uint256",
      },
    ],
    name: "buy",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "created",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_creator",
        type: "address",
      },
    ],
    name: "curate",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "_name",
        type: "string",
      },
      {
        internalType: "address",
        name: "_bondingCurve",
        type: "address",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "isCuratingLayer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "poolBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "ppm",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_creator",
        type: "address",
      },
    ],
    name: "removeCuration",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "removeLayer",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "reserveRatio",
    outputs: [
      {
        internalType: "uint32",
        name: "",
        type: "uint32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_tokens",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_minETHReturned",
        type: "uint256",
      },
    ],
    name: "sell",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50612bbb806100206000396000f3fe6080604052600436106100fd5760003560e01c80635c1c13f31161009557806396365d441161006457806396365d4414610314578063d42efd831461033f578063d6febde81461037c578063d79875eb14610398578063eff1d50e146103c1576100fd565b80635c1c13f3146102675780636eea662c1461029057806370a08231146102bb5780637ab4339d146102f8576100fd565b80632698747a116100d15780632698747a1461019a5780633143d139146101c35780634f956f3b146102005780635a6527581461023e576100fd565b80627b572c1461010257806306fdde03146101195780630c7d5cd81461014457806318160ddd1461016f575b600080fd5b34801561010e57600080fd5b506101176103ec565b005b34801561012557600080fd5b5061012e610649565b60405161013b91906123a6565b60405180910390f35b34801561015057600080fd5b506101596106d7565b6040516101669190612636565b60405180910390f35b34801561017b57600080fd5b506101846106ed565b6040516101919190612568565b60405180910390f35b3480156101a657600080fd5b506101c160048036038101906101bc9190612026565b6106f3565b005b3480156101cf57600080fd5b506101ea60048036038101906101e59190611f92565b61099e565b6040516101f7919061238b565b60405180910390f35b34801561020c57600080fd5b5061022760048036038101906102229190611f69565b6109cd565b60405161023592919061235b565b60405180910390f35b34801561024a57600080fd5b5061026560048036038101906102609190611f69565b610a99565b005b34801561027357600080fd5b5061028e60048036038101906102899190611f69565b610cd9565b005b34801561029c57600080fd5b506102a5610f17565b6040516102b29190612636565b60405180910390f35b3480156102c757600080fd5b506102e260048036038101906102dd9190611f69565b610f2d565b6040516102ef9190612568565b60405180910390f35b610312600480360381019061030d9190611fce565b610f45565b005b34801561032057600080fd5b506103296110c4565b6040516103369190612568565b60405180910390f35b34801561034b57600080fd5b5061036660048036038101906103619190611f69565b6110ca565b604051610373919061238b565b60405180910390f35b61039660048036038101906103919190612090565b6110ea565b005b3480156103a457600080fd5b506103bf60048036038101906103ba9190612090565b61141f565b005b3480156103cd57600080fd5b506103d66117a8565b6040516103e39190612340565b60405180910390f35b336000603860008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020541161046f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161046690612528565b60405180910390fd5b603960003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff166104fb576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104f2906123c8565b60405180910390fd5b610503611d1f565b80603b60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008201518160000160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060208201518160010190805190602001906105a6929190611d4f565b509050506000603960003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055503373ffffffffffffffffffffffffffffffffffffffff167f4f43ce8ea1c21bc94dd7670b7b9092ec6e9febef801db4fcd3fa4997b43f0afb60405160405180910390a25050565b60348054610656906127f2565b80601f0160208091040260200160405190810160405280929190818152602001828054610682906127f2565b80156106cf5780601f106106a4576101008083540402835291602001916106cf565b820191906000526020600020905b8154815290600101906020018083116106b257829003601f168201915b505050505081565b603560009054906101000a900463ffffffff1681565b60375481565b336000603860008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205411610776576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161076d90612528565b60405180910390fd5b603960003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff1615610803576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016107fa906123e8565b60405180910390fd5b61080b611d1f565b82816020018190525033816000019073ffffffffffffffffffffffffffffffffffffffff16908173ffffffffffffffffffffffffffffffffffffffff16815250506001603960003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff02191690831515021790555080603b60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008201518160000160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506020820151816001019080519060200190610947929190611d4f565b509050503373ffffffffffffffffffffffffffffffffffffffff167ff64a96f01ea6480ae3021f137b8963dafae52852646cf8d47bcee06ca46b93a58460405161099191906123a6565b60405180910390a2505050565b603a6020528160005260406000206020528060005260406000206000915091509054906101000a900460ff1681565b603b6020528060005260406000206000915090508060000160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1690806001018054610a16906127f2565b80601f0160208091040260200160405190810160405280929190818152602001828054610a42906127f2565b8015610a8f5780601f10610a6457610100808354040283529160200191610a8f565b820191906000526020600020905b815481529060010190602001808311610a7257829003601f168201915b5050505050905082565b336000603860008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205411610b1c576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610b1390612528565b60405180910390fd5b603a60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff1615610be6576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610bdd906124a8565b60405180910390fd5b6001603a60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055508173ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167ff1f0c689898dd3f543fc22717bc74a6d5d00314bfaca5f9171a43f98a865431c60405160405180910390a35050565b336000603860008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205411610d5c576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610d5390612528565b60405180910390fd5b603a60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060009054906101000a900460ff16610e25576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610e1c906124e8565b60405180910390fd5b6000603a60003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060006101000a81548160ff0219169083151502179055508173ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167e060a27e3af9f1baec344dc7dc0e22c7cecdb113803555502aaa970d4658d6c60405160405180910390a35050565b603560049054906101000a900463ffffffff1681565b60386020528060005260406000206000915090505481565b600060019054906101000a900460ff1680610f6b575060008054906101000a900460ff16155b610faa576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610fa190612488565b60405180910390fd5b60008060019054906101000a900460ff161590508015610ffa576001600060016101000a81548160ff02191690831515021790555060016000806101000a81548160ff0219169083151502179055505b62051615603560006101000a81548163ffffffff021916908363ffffffff160217905550620f4240603560046101000a81548163ffffffff021916908363ffffffff160217905550838360349190611053929190611dd5565b5081603360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555061109d6117ce565b80156110be5760008060016101000a81548160ff0219169083151502179055505b50505050565b60365481565b60396020528060005260406000206000915054906101000a900460ff1681565b81341480156110f95750600034115b611138576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161112f90612428565b60405180910390fd5b6000811161117b576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161117290612448565b60405180910390fd5b600080603754141561129057603360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663e895d02984603560009054906101000a900463ffffffff166040518363ffffffff1660e01b81526004016111f692919061260d565b60206040518083038186803b15801561120e57600080fd5b505afa158015611222573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906112469190612067565b90508181101561128b576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161128290612408565b60405180910390fd5b61139f565b603360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166329a00e7c603754603654603560009054906101000a900463ffffffff16876040518563ffffffff1660e01b815260040161130794939291906125c8565b602060405180830381600087803b15801561132157600080fd5b505af1158015611335573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906113599190612067565b90508181101561139e576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161139590612408565b60405180910390fd5b5b6113a933826118af565b82603660008282546113bb91906126ce565b925050819055503373ffffffffffffffffffffffffffffffffffffffff167f064fb1933e186be0b289a87e98518dc18cc9856ecbc9f1353d1a138ddf733ec560365460375484876040516114129493929190612583565b60405180910390a2505050565b336000603860008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054116114a2576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161149990612528565b60405180910390fd5b600260015414156114e8576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016114df90612548565b60405180910390fd5b600260018190555060008311801561153f5750603860003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020548311155b61157e576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611575906124c8565b60405180910390fd5b6000603654116115c3576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016115ba90612508565b60405180910390fd5b60008211611606576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016115fd90612448565b60405180910390fd5b6000603360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166349f9b0f7603754603654603560009054906101000a900463ffffffff16886040518563ffffffff1660e01b815260040161167f94939291906125c8565b602060405180830381600087803b15801561169957600080fd5b505af11580156116ad573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906116d19190612067565b905082811015611716576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161170d90612408565b60405180910390fd5b61172033856119bb565b80603660008282546117329190612724565b925050819055506117433382611ac7565b3373ffffffffffffffffffffffffffffffffffffffff167f483f8aec0fd892ac72ad1ba8d0e9c9e73db59c12d263fd71de480b5b3deeae3c60365460375487856040516117939493929190612583565b60405180910390a25060018081905550505050565b603360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600060019054906101000a900460ff16806117f4575060008054906101000a900460ff16155b611833576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161182a90612488565b60405180910390fd5b60008060019054906101000a900460ff161590508015611883576001600060016101000a81548160ff02191690831515021790555060016000806101000a81548160ff0219169083151502179055505b61188b611c3f565b80156118ac5760008060016101000a81548160ff0219169083151502179055505b50565b806037546118bd91906126ce565b60378190555080603860008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461190e91906126ce565b603860008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff16600073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef836040516119af9190612568565b60405180910390a35050565b80603860008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054611a069190612724565b603860008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555080603754611a579190612724565b603781905550600073ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051611abb9190612568565b60405180910390a35050565b60026001541415611b0d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611b0490612548565b60405180910390fd5b600260018190555080471015611b58576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611b4f90612468565b60405180910390fd5b60008273ffffffffffffffffffffffffffffffffffffffff1682604051611b7e9061232b565b60006040518083038185875af1925050503d8060008114611bbb576040519150601f19603f3d011682016040523d82523d6000602084013e611bc0565b606091505b505090503373ffffffffffffffffffffffffffffffffffffffff163073ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef84604051611c219190612568565b60405180910390a380611c3357600080fd5b50600180819055505050565b600060019054906101000a900460ff1680611c65575060008054906101000a900460ff16155b611ca4576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401611c9b90612488565b60405180910390fd5b60008060019054906101000a900460ff161590508015611cf4576001600060016101000a81548160ff02191690831515021790555060016000806101000a81548160ff0219169083151502179055505b600180819055508015611d1c5760008060016101000a81548160ff0219169083151502179055505b50565b6040518060400160405280600073ffffffffffffffffffffffffffffffffffffffff168152602001606081525090565b828054611d5b906127f2565b90600052602060002090601f016020900481019282611d7d5760008555611dc4565b82601f10611d9657805160ff1916838001178555611dc4565b82800160010185558215611dc4579182015b82811115611dc3578251825591602001919060010190611da8565b5b509050611dd19190611e5b565b5090565b828054611de1906127f2565b90600052602060002090601f016020900481019282611e035760008555611e4a565b82601f10611e1c57803560ff1916838001178555611e4a565b82800160010185558215611e4a579182015b82811115611e49578235825591602001919060010190611e2e565b5b509050611e579190611e5b565b5090565b5b80821115611e74576000816000905550600101611e5c565b5090565b6000611e8b611e8684612676565b612651565b905082815260208101848484011115611ea357600080fd5b611eae8482856127b0565b509392505050565b600081359050611ec581612b57565b92915050565b60008083601f840112611edd57600080fd5b8235905067ffffffffffffffff811115611ef657600080fd5b602083019150836001820283011115611f0e57600080fd5b9250929050565b600082601f830112611f2657600080fd5b8135611f36848260208601611e78565b91505092915050565b600081359050611f4e81612b6e565b92915050565b600081519050611f6381612b6e565b92915050565b600060208284031215611f7b57600080fd5b6000611f8984828501611eb6565b91505092915050565b60008060408385031215611fa557600080fd5b6000611fb385828601611eb6565b9250506020611fc485828601611eb6565b9150509250929050565b600080600060408486031215611fe357600080fd5b600084013567ffffffffffffffff811115611ffd57600080fd5b61200986828701611ecb565b9350935050602061201c86828701611eb6565b9150509250925092565b60006020828403121561203857600080fd5b600082013567ffffffffffffffff81111561205257600080fd5b61205e84828501611f15565b91505092915050565b60006020828403121561207957600080fd5b600061208784828501611f54565b91505092915050565b600080604083850312156120a357600080fd5b60006120b185828601611f3f565b92505060206120c285828601611f3f565b9150509250929050565b6120d581612758565b82525050565b6120e48161276a565b82525050565b60006120f5826126a7565b6120ff81856126bd565b935061210f8185602086016127bf565b612118816128e2565b840191505092915050565b60006121306010836126bd565b915061213b826128f3565b602082019050919050565b60006121536008836126b2565b915061215e8261291c565b600882019050919050565b6000612176600f836126bd565b915061218182612945565b602082019050919050565b60006121996008836126bd565b91506121a48261296e565b602082019050919050565b60006121bc600d836126bd565b91506121c782612997565b602082019050919050565b60006121df6010836126bd565b91506121ea826129c0565b602082019050919050565b6000612202600b836126bd565b915061220d826129e9565b602082019050919050565b6000612225602e836126bd565b915061223082612a12565b604082019050919050565b6000612248600f836126bd565b915061225382612a61565b602082019050919050565b600061226b6011836126bd565b915061227682612a8a565b602082019050919050565b600061228e6010836126bd565b915061229982612ab3565b602082019050919050565b60006122b16004836126bd565b91506122bc82612adc565b602082019050919050565b60006122d46010836126bd565b91506122df82612b05565b602082019050919050565b60006122f7601f836126bd565b915061230282612b2e565b602082019050919050565b61231681612796565b82525050565b612325816127a0565b82525050565b600061233682612146565b9150819050919050565b600060208201905061235560008301846120cc565b92915050565b600060408201905061237060008301856120cc565b818103602083015261238281846120ea565b90509392505050565b60006020820190506123a060008301846120db565b92915050565b600060208201905081810360008301526123c081846120ea565b905092915050565b600060208201905081810360008301526123e181612123565b9050919050565b6000602082019050818103600083015261240181612169565b9050919050565b600060208201905081810360008301526124218161218c565b9050919050565b60006020820190508181036000830152612441816121af565b9050919050565b60006020820190508181036000830152612461816121d2565b9050919050565b60006020820190508181036000830152612481816121f5565b9050919050565b600060208201905081810360008301526124a181612218565b9050919050565b600060208201905081810360008301526124c18161223b565b9050919050565b600060208201905081810360008301526124e18161225e565b9050919050565b6000602082019050818103600083015261250181612281565b9050919050565b60006020820190508181036000830152612521816122a4565b9050919050565b60006020820190508181036000830152612541816122c7565b9050919050565b60006020820190508181036000830152612561816122ea565b9050919050565b600060208201905061257d600083018461230d565b92915050565b6000608082019050612598600083018761230d565b6125a5602083018661230d565b6125b2604083018561230d565b6125bf606083018461230d565b95945050505050565b60006080820190506125dd600083018761230d565b6125ea602083018661230d565b6125f7604083018561231c565b612604606083018461230d565b95945050505050565b6000604082019050612622600083018561230d565b61262f602083018461231c565b9392505050565b600060208201905061264b600083018461231c565b92915050565b600061265b61266c565b90506126678282612824565b919050565b6000604051905090565b600067ffffffffffffffff821115612691576126906128b3565b5b61269a826128e2565b9050602081019050919050565b600081519050919050565b600081905092915050565b600082825260208201905092915050565b60006126d982612796565b91506126e483612796565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111561271957612718612855565b5b828201905092915050565b600061272f82612796565b915061273a83612796565b92508282101561274d5761274c612855565b5b828203905092915050565b600061276382612776565b9050919050565b60008115159050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b600063ffffffff82169050919050565b82818337600083830152505050565b60005b838110156127dd5780820151818401526020810190506127c2565b838111156127ec576000848401525b50505050565b6000600282049050600182168061280a57607f821691505b6020821081141561281e5761281d612884565b5b50919050565b61282d826128e2565b810181811067ffffffffffffffff8211171561284c5761284b6128b3565b5b80604052505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6000601f19601f8301169050919050565b7f48415645204e4f54204352454154454400000000000000000000000000000000600082015250565b7f5245564552544544000000000000000000000000000000000000000000000000600082015250565b7f414c524541445920435245415445440000000000000000000000000000000000600082015250565b7f534c495050414745000000000000000000000000000000000000000000000000600082015250565b7f494e56414c494420505249434500000000000000000000000000000000000000600082015250565b7f494e56414c494420534c49505041474500000000000000000000000000000000600082015250565b7f494e56414c494420414d54000000000000000000000000000000000000000000600082015250565b7f496e697469616c697a61626c653a20636f6e747261637420697320616c72656160008201527f647920696e697469616c697a6564000000000000000000000000000000000000602082015250565b7f414c524541445920435552415445440000000000000000000000000000000000600082015250565b7f494e56414c494420544f4b454e20414d54000000000000000000000000000000600082015250565b7f48415645204e4f54204355524154454400000000000000000000000000000000600082015250565b7f50423c3000000000000000000000000000000000000000000000000000000000600082015250565b7f4d55535420484f4c4420544f4b454e5300000000000000000000000000000000600082015250565b7f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00600082015250565b612b6081612758565b8114612b6b57600080fd5b50565b612b7781612796565b8114612b8257600080fd5b5056fea264697066735822122097fb407516d409601ef0f6b684657f44803734970d16926c050fb98d559da35564736f6c63430008040033";

export class Cryptomedia__factory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<Cryptomedia> {
    return super.deploy(overrides || {}) as Promise<Cryptomedia>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): Cryptomedia {
    return super.attach(address) as Cryptomedia;
  }
  connect(signer: Signer): Cryptomedia__factory {
    return super.connect(signer) as Cryptomedia__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): CryptomediaInterface {
    return new utils.Interface(_abi) as CryptomediaInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): Cryptomedia {
    return new Contract(address, _abi, signerOrProvider) as Cryptomedia;
  }
}
