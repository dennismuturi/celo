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
  event CandidateCreated(address indexed owner, string name);
  event VoteCasted(address indexed voter, address indexed candidateOwner, uint index);
}


import "@openzeppelin/contracts/access/Ownable.sol";
contract Vote is Ownable {
 

   uint internal candidatesLength = 0;
   uint[] private candidatesSortedByVotes;
   address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

   struct Candidate {
       address payable owner;
       string name;
       string image;
       string description;
       uint price;
       uint votes;
   }

   mapping (uint => Candidate) private candidates;
   mapping (string => uint) private candidateIndexByName;
   mapping (address => uint[]) private votedCandidatesByUser;

   event CandidateCreated(address indexed owner, string name);
  event VoteCasted(address indexed voter, address indexed candidateOwner, uint index);

   function writeCandidate (
        string memory _name,
        string memory _image,
        string memory _description
        ) public onlyOwner {
        uint price = 1;
        uint _votes = 0;
       candidates[candidatesLength] = Candidate(
           payable(msg.sender),
           _name,
           _image,
           _description,
            price,
           _votes
       );
       candidateIndexByName[_name] = candidatesLength;
       candidatesLength ++;
   }

   function getCandidateByName(string memory _name) public view returns (
        address payable,
        string memory,
        string memory,
        string memory,
        uint,
        uint
    ) {
        uint index = candidateIndexByName[_name];
        require(index != 0, "Candidate not found");
        return readCandidate(index - 1);
    }


   function readCandidate (uint _index) public view returns (
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
      require (IERC20Token(cUsdTokenAddress).transferFrom(
		  	msg.sender,//address of the sender
		  	candidates[_index].owner,// recipient of the transaction i.e entity that created the candidate
		  	candidates[_index].price
		    ),
		    "Transfer failed."
		  );
          votedCandidatesByUser[msg.sender].push(_index);
          sortCandidatesByVotes();
		  candidates[_index].votes++;
      emit VoteCasted(msg.sender, candidates[_index].owner, _index);
	}

    function sortCandidatesByVotes() private {
        uint[] memory sortedIndices = new uint[](candidatesLength);
        for (uint i = 0; i < candidatesLength; i++) {
            sortedIndices[i] = i;
        }

        for (uint i = 0; i < candidatesLength - 1; i++) {
            for (uint j = i + 1; j < candidatesLength; j++) {
                if (candidates[sortedIndices[i]].votes < candidates[sortedIndices[j]].votes) {
                    uint temp = sortedIndices[i];
                    sortedIndices[i] = sortedIndices[j];
                    sortedIndices[j] = temp;
                }
            }
        }

        candidatesSortedByVotes = sortedIndices;
    }

    function getSortedCandidatesByVotes() public view returns (uint[] memory) {
        return candidatesSortedByVotes;
    }

    function getVotedCandidatesByUser(address _user) public view returns (uint[] memory) {
         require(votedCandidatesByUser[msg.sender].length > 0, "Only voters can call this function");
        return votedCandidatesByUser[_user];
    }
        
    function getCandidatesLength() public view returns (uint){
        return (candidatesLength);
    }



}
