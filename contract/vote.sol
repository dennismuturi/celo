/**
 SPDX-License-Identifier: MIT
 */
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


import "@openzeppelin/contracts/access/Ownable.sol";
contract Vote is Ownable {
 
    /**
    * @dev Internal variable to keep track of the number of candidates.
    */
    uint internal candidatesLength = 0;

    /**
    * @dev Private array to store the indices of candidates sorted by votes.
    */
    uint[] private candidatesSortedByVotes;

    /**
    * @dev Internal variable to store the address of the cUSD token contract.
    */
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    /**
    * @dev Struct representing a candidate.
    * Contains details such as the owner, name, image, description, price, and votes.
    */
    struct Candidate {
        address payable owner;
        string name;
        string image;
        string description;
        uint price;
        uint votes;
    }

    /**
    * @dev Mapping of candidate index to candidate details.
    * Each candidate is represented by an index that maps to their details.
    */
    mapping (uint => Candidate) private candidates;

    /**
    * @dev Mapping of candidate name to candidate index.
    * Allows efficient lookup of candidate index by name.
    */
    mapping (string => uint) private candidateIndexByName;

    /**
    * @dev Mapping of user address to an array of candidate indices they have voted for.
    * Allows tracking of candidates voted by each user.
    */
    mapping (address => uint[]) private votedCandidatesByUser;

    /**
    * @dev Event emitted when a new candidate is created.
    * @param owner The address of the candidate owner.
    * @param name The name of the candidate.
    */
   event CandidateCreated(address indexed owner, string name);

    /**
    * @dev Event emitted when a voter casts a vote for a candidate.
    * @param voter The address of the voter.
    * @param candidateOwner The address of the candidate owner.
    * @param index The index of the candidate.
    */
   event VoteCasted(address indexed voter, address indexed candidateOwner, uint index);

    /**
     * @dev Function to write a candidate.
     * @param _name The name of the candidate.
     * @param _image The image URL of the candidate.
     * @param _description The description of the candidate.
     */
   function writeCandidate (
         string memory _name,
         string memory _image,
         string memory _description
         ) public onlyOwner {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(candidateIndexByName[_name] == 0, "Candidate name already exists");
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


     /**
     * @dev Function to get candidate details by name.
     * @param _name The name of the candidate.
     * @return The candidate details.
     */
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

    /**
     * @dev Function to get candidate details by index.
     * @param _index The index of the candidate.
     * @return The candidate details.
     */
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
 
    /**
     * @dev Function to vote for a candidate.
     * @param _index The index of the candidate to vote for.
     */
    function vote(uint _index) public payable {
        require(_index < candidatesLength, "Invalid candidate index");
        require(candidateIndexByName[candidates[_index].name] != 0, "Candidate not found");
        require(votedCandidatesByUser[msg.sender].length == 0 || !hasVotedForCandidate(msg.sender, _index), "Already voted for the same candidate");
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

    /**
     * @dev Helper function to check if a voter has already voted for a specific candidate.
     * @param _voter The address of the voter.
     * @param _candidateIndex The index of the candidate.
     * @return A boolean indicating whether the voter has already voted for the candidate.
     */
    function hasVotedForCandidate(address _voter, uint _candidateIndex) private view returns (bool) {
        uint[] storage votedCandidates = votedCandidatesByUser[_voter];
        for (uint i = 0; i < votedCandidates.length; i++) {
            if (votedCandidates[i] == _candidateIndex) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Function to sort candidates by votes.
     */
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


    /**
     * @dev Function to get candidates sorted by votes.
     * @return An array of candidate indices sorted by votes.
     */
    function getSortedCandidatesByVotes() public view returns (uint[] memory) {
        return candidatesSortedByVotes;
    }

    /**
     * @dev Function to get the list of candidates voted by a user.
     * @param _user The address of the user.
     * @return An array of candidate indices voted by the user.
     */
    function getVotedCandidatesByUser(address _user) public view returns (uint[] memory) {
         require(votedCandidatesByUser[msg.sender].length > 0, "Only voters can call this function");
        return votedCandidatesByUser[_user];
    }

    /**
     * @dev Function to get the total number of candidates.
     * @return The total number of candidates.
    */    
    function getCandidatesLength() public view returns (uint){
        return (candidatesLength);
    }


}
