// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Vote {
  struct Candidate {
    address payable owner;
    string name;
    string image;
    string description;
    uint price;
    uint votes;
  }

  uint internal candidatesLength = 0;
  address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

  mapping (uint => Candidate) internal candidates;

  function writeCandidate(
    string memory _name,
    string memory _image,
    string memory _description
  ) public {
    candidates[candidatesLength] = Candidate(
      payable(msg.sender),
      _name,
      _image,
      _description,
      1, // Initialize price directly in the struct
      0  // Initialize votes directly in the struct
    );
    candidatesLength++;
  }

  function readCandidate(uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    uint,
    uint
  ) {
    return (
      candidates[_index].owner,
      candidates[_index].name,
      candidates[_index].image,
      candidates[_index].description,
      candidates[_index].price,
      candidates[_index].votes
    );
  }

  function vote(uint _index) public payable {
    require (
      IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        candidates[_index].owner,
        candidates[_index].price
      ),
      "Transfer failed."
    );
    candidates[_index].votes++;
  }

  function getCandidatesLength() public view returns (uint) {
    return candidatesLength;
  }
}
