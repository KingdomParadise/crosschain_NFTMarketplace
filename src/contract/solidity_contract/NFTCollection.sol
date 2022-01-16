// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTCollection is ERC721, ERC721Enumerable {

  using SafeMath for uint256;  //For Future use

  uint public offerCount;
  string[] public tokenURIs;

  mapping(string => bool) _tokenURIExists; //the variable if the tokenURI is exist
  mapping(uint => string) _tokenIdToTokenURI; //mapping tokenId to tokenURI

  mapping (uint => _Offer) public offers; //mapping offerId to Offer    ?
  mapping (address => uint) public userFunds; // the funds of user's address

  //variables that remain static or connstant
  mapping(uint256 => ArtItem) private _artItems;  //Map id to ArtItem   ?
  address public owner;   //owner address

  //variables that are dynamic or change
  uint256 public _tokenIds;  //Unique Image ID that are tokenized
  uint256 public _artItemIds; //Unique ID up images for sale but not tokenized
  bool public canceled;
  mapping(uint256=>mapping(address => uint256)) public fundsByBidder; //map tokenid to fundsByBidder
  mapping(uint256=>bidding) public bid;  //mapping tokenid to bidding
  bool auctionstarted = false;  //to check if auction started
  bool firsttime = false;  //to mart first successfull bid

 //offer struct
  struct _Offer {
    uint offerId;
    uint id;
    address user;
    uint price;
    bool fulfilled;
    bool cancelled;
  }

  event Offer(
    uint offerId,
    uint id,
    address user,
    uint price,
    bool fulfilled,
    bool cancelled
  );

  //Art Item 
  struct ArtItem {
    address payable seller; //address of seller
    uint256 minbid; //minimum price by artist
    string tokenURI;  //IPFS URL
    bool exists;    //token by id exists or not
    uint bidIncrement; //incremention of bid
  }
    
  struct bidding{
    uint highestBindingBid; //highestBindingBid of the tokenid
    address payable highestBidder;
  }
  //Events
  event OfferFilled(uint offerId, uint id, address newOwner);
  event OfferCancelled(uint offerId, uint id, address owner);
  event ClaimFunds(address user, uint amount);

  event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);   
  event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
  event LogCanceled();

  constructor() 
    ERC721("lEOS Collection", "lEOS") 
  {
    owner=msg.sender;
  }

  //modifiers
  
  modifier artItemExist(uint256 id) {   //check if item exists
    require(_artItems[id].exists, "Not Found");
    _;
  }
    
  modifier onlyNotOwner(uint256 id) {            //Check if owner is calling
    ArtItem memory artItem = _artItems[id];   
    if (msg.sender == artItem.seller) revert();
    _;
  }

  modifier onlyNotCanceled{        //Auction only if is not cancelled
    if (canceled) revert();
    _;
  }
    
  modifier onlyOwner(uint256 id){
    ArtItem memory artItem = _artItems[id];   
    if (msg.sender != artItem.seller) revert();
    _;
  }

  modifier minbid(uint256 id){
    ArtItem memory artItem = _artItems[id];
    if(msg.value<artItem.minbid) revert();
    _;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return _tokenIdToTokenURI[tokenId];
  }

  function safeMint(string memory _tokenURI) public {
    require(!_tokenURIExists[_tokenURI], 'The token URI should be unique');
    tokenURIs.push(_tokenURI);    
    uint _id = tokenURIs.length;
    _tokenIdToTokenURI[_id] = _tokenURI;
    _safeMint(msg.sender, _id);
    _tokenURIExists[_tokenURI] = true;
  }

  function makeOffer(uint _id, uint _price, address nftcollection) public {
    transferFrom(msg.sender, nftcollection, _id);
    offerCount ++;
    offers[offerCount] = _Offer(offerCount, _id, msg.sender, _price, false, false);
    emit Offer(offerCount, _id, msg.sender, _price, false, false);
  }

  function fillOffer(uint _offerId, address nftcollection) public payable {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user != msg.sender, 'The owner of the offer cannot fill it');
    require(!_offer.fulfilled, 'An offer cannot be fulfilled twice');
    require(!_offer.cancelled, 'A cancelled offer cannot be fulfilled');
    require(msg.value == _offer.price, 'The ETH amount should match with the NFT Price');
    transferFrom(nftcollection, msg.sender, _offer.id);
    _offer.fulfilled = true;
    userFunds[_offer.user] += msg.value;
    emit OfferFilled(_offerId, _offer.id, msg.sender);
  }

  function cancelOffer(uint _offerId, address nftcollection) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId, 'The offer must exist');
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'A fulfilled offer cannot be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    transferFrom(nftcollection, msg.sender, _offer.id);
    _offer.cancelled = true;
    emit OfferCancelled(_offerId, _offer.id, msg.sender);
  }

  function claimFunds() public {
    require(userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
    payable(msg.sender).transfer(userFunds[msg.sender]);
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }

  function addArtItem(uint256 price, string memory _tokenURI, uint _bidincrement) public {
    require(price >= 0, "Price cannot be lesss than 0");

    _artItemIds++;
    address seller = msg.sender;
    _artItems[_artItemIds] = ArtItem(payable(seller), price, _tokenURI, true, _bidincrement );
  }

  function getArtItem(uint256 id)   //get art item info
    public
    view
    artItemExist(id)
    returns (
        uint256,
        uint256,
        string memory,
        uint256
    )
  {
    ArtItem memory artItem = _artItems[id];
    return (id, artItem.minbid, artItem.tokenURI, bid[id].highestBindingBid);
  }
    
  //auction functions : 
    
  //Cancel auction
  function cancelAuction(uint256 id) public payable
    onlyOwner(id)
    onlyNotCanceled()
    returns (bool success)
   {
    canceled = true;
    
    if(auctionstarted==true)  //mint token if auctionstarted
    {
    ArtItem memory artItem = _artItems[id];   
    // bidding storage bid = bid[id]; 
    _tokenIds++; 
    // _safeMint(msg.sender, _tokenIds);
    safeMint(artItem.tokenURI);
    // _setTokenURI(_tokenIds, artItem.tokenURI);
    
    // _tokenIdToTokenURI(_tokenIds) = artItem.tokenURI;
     // the auction's owner should be allowed to withdraw the highestBindingBid
    
    if (bid[id].highestBindingBid == 0) revert();
    fundsByBidder[id][bid[id].highestBidder] -= bid[id].highestBindingBid;
    // send the funds
    address seller = msg.sender;
    if (!payable(seller).send(bid[id].highestBindingBid)) revert();
        } 
    
    emit LogCanceled();
    return true;
   }
   
   function placeBid(uint256 id) public
    payable
    onlyNotCanceled
    onlyNotOwner(id)
    minbid(id)
    
    returns (bool success)
    {
    // reject payments of 0 ETH
    if (msg.value == 0) revert();
    
    // calculate the user's total bid based on the current amount they've sent to the contract
    // plus whatever has been sent with this transaction
    // bidding storage bid = bid[id]; 
    auctionstarted = true;
    ArtItem memory artItem = _artItems[id];  

    uint newBid = fundsByBidder[id][msg.sender] + msg.value;
    

    // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
    // to do except revert the transaction.
    if (newBid <= bid[id].highestBindingBid) revert();

    // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
    // highestBidder and is just increasing their maximum bid).
    uint highestBid = fundsByBidder[id][bid[id].highestBidder];

    fundsByBidder[id][msg.sender] = newBid;

    if (newBid <= highestBid) {
        // if the user has overbid the highestBindingBid but not the highestBid, we simply
        // increase the highestBindingBid and leave highestBidder alone.

        // note that this case is impossible if msg.sender == highestBidder because you can never
        // bid less ETH than you already have.
        if(newBid+artItem.bidIncrement> highestBid)
        {
            bid[id].highestBindingBid = highestBid;
        }
        else
        {
            bid[id].highestBindingBid = newBid+artItem.bidIncrement;
        }
    } else {
        // if msg.sender is already the highest bidder, they must simply be wanting to raise
        // their maximum bid, in which case we shouldn't increase the highestBindingBid.

        // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
        // as the new highestBidder and recalculate highestBindingBid.

        if (msg.sender != bid[id].highestBidder) {
            bid[id].highestBidder = payable(msg.sender);
        if(newBid+artItem.bidIncrement> highestBid)
        {   if(firsttime==false)
            bid[id].highestBindingBid = highestBid;
            else
            {bid[id].highestBindingBid = artItem.minbid + artItem.bidIncrement;
            firsttime=true;
            }
        }
        else
        {
            bid[id].highestBindingBid = newBid+artItem.bidIncrement;
        }
        }
        highestBid = newBid;
    }

    emit LogBid(msg.sender, newBid, bid[id].highestBidder, highestBid, bid[id].highestBindingBid);
    return true;
    }
    
    function withdraw(uint256 id) public payable onlyNotOwner(id)
    returns (bool success) 
    {   
    require(canceled==true);
    require(auctionstarted==true);
    address payable withdrawalAccount;
    uint withdrawalAmount;
    // bidding storage bid = bid[id]; 
    
        if (msg.sender == bid[id].highestBidder) {
            // the highest bidder should only be allowed to withdraw the difference between their
            // highest bid and the highestBindingBid
            withdrawalAccount = bid[id].highestBidder;
            withdrawalAmount = fundsByBidder[id][bid[id].highestBidder];
        }
        else {
            // anyone who participated but did not win the auction should be allowed to withdraw
            // the full amount of their funds
            withdrawalAccount = payable(msg.sender);
            withdrawalAmount = fundsByBidder[id][withdrawalAccount];
        }

    if (withdrawalAmount == 0) revert();

    fundsByBidder[id][withdrawalAccount] -= withdrawalAmount;

    // send the funds
    if (!payable(msg.sender).send(withdrawalAmount)) revert();

    emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

    return true;
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback () external {
        revert();
    }
}
