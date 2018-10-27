import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract ERC721Metadata {
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}




contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


contract CardBase is usingOraclize{

  event Transfer(address from, address to, uint256 tokenId);
  event Auction(address owner, uint32 class, uint256 attribute, uint32 timeBlock);
  event Create(address owner, uint32 class, uint256 attribute);
  event Dead(address owner, uint256 tokenId);
  event Attack(address attacker, uint256 tokenId1, address defender, uint256 tokenId2);

    struct Card{
      uint256 _tokenId;
      uint32 _class;
      uint256 _attribute;
      uint32 life;
      address owner;
    }
    Card[] Cards;
    uint128 public constant totalCards = uint128(708100);
    uint32 constant public LuckyFee = uint32(1000);
    uint128 public countCards;
    uint32[5] public CardClass = [
        uint32(100),
        uint32(8000),
        uint32(50000),
        uint32(300000),
        uint32(350000)
    ];
    uint32[5] public CurrentClass ;

    mapping (uint256 => address) public CardIndexToOwner;
    mapping (address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public CardIndexToApproved;
    mapping (uint256 => address) public sireAllowedToAddress;

    SaleClockAuction public saleAuction;
    //SiringClockAuction public siringAuction;

    function attack(uint256 _from, uint256 _to)returns(bool){
      Card card1 = Cards[_from];
      Card card2 = Cards[_to];
      require(card1.owner==msg.sender);
        if(compare(card1._class,card2._class)){
          card2.life--;
          if(card2.life==0){
            dead(card2.owner,_to);
            return true;
          }
        }
        else{
          card1.life--;
          if(card1.life==0){
            dead(card1.owner,_to);
            return false;
          }
        }

    }

    function dead(address owner, uint256 _tokenId){
      Dead(owner,_tokenId);
      Cards[_tokenId].owner=address(0);
      CurrentClass[Cards[_tokenId]._class]--;
      ownershipTokenCount[owner]--;
      delete sireAllowedToAddress[_tokenId];
      delete CardIndexToApproved[_tokenId];
    }

    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;

    function rand() public  view returns(uint256) {
      uint256 factor = FACTOR * 100 / totalCards;

      uint256 lastBlockNumber = block.number - 1;

      uint256 hashVal = uint256(block.blockhash(lastBlockNumber));

      return uint256((uint256(hashVal) / factor)) ;
    }
    function compare(uint256 _from,uint256 _to)view returns(bool){
      uint32 ran = uint32(rand()%10);
      if(_from-_to>1)
        return true;
      if(_to-_from>1)
        return false;
      if(_from-_to==1)
      {
	         if(ran==9)
	             return false;
	         else
	    return true;
      }
      if(_to-_from==1)
      {
	        if(ran==9)
	    return true;
	     else
	    return false;
      }
      if(_from==_to)
      {
	       if(ran>=0&&ran<=4)
	        return true;
          else
          return false;
        }
      }

    function GiftCard(){
      uint32 ind;
        msg.sender.send(LuckyFee);
        for(ind=0;ind<3;ind++){
          require(countCards<=totalCards);
          _createCard(msg.sender);

        }
    }
    function _createCard(address _owner)
        internal
        returns (uint)
    {
        uint256 attribute=rand();
        uint256 rnum = rand()%totalCards;
        uint32 class;
        if(rnum<=100&&CurrentClass[0]<=CardClass[0])class=0;
        else if(rnum<=8100&&CurrentClass[1]<=CardClass[1])class=1;
        else if(rnum<=58100&&CurrentClass[2]<=CardClass[2])class=2;
        else if(rnum<=358100&&CurrentClass[3]<=CardClass[3])class=3;
        else {require(countCards<=totalCards);class=4;}
        CurrentClass[class]++;
        countCards++;

        Card memory _card = Card({
          _tokenId:0,
          _class:class,
          _attribute:attribute,
          life:5,
          owner:_owner
        });
        uint256 newCardId = Cards.push(_card) - 1;

        _card._tokenId=newCardId;
        require(newCardId == uint256(uint32(newCardId)));

        Create(
            _owner,
            class,
            attribute
        );

        _transfer(0, _owner, newCardId);

        return newCardId;
    }





    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        CardIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            Cards[_tokenId].owner=_to;
            ownershipTokenCount[_from]--;
            delete sireAllowedToAddress[_tokenId];
            delete CardIndexToApproved[_tokenId];

        }
        Transfer(_from, _to, _tokenId);
    }
}

contract CardOwnership is CardBase, ERC721 {
    string public constant name = "CardGame";
    string public constant symbol = "CG";

    ERC721Metadata public erc721Metadata;

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256,string)'));


    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }
    function setMetadataAddress(address _contractAddress) {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return CardIndexToOwner[_tokenId] == _claimant;
    }
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return CardIndexToApproved[_tokenId] == _claimant;
    }
    function _approve(uint256 _tokenId, address _approved) internal {
        CardIndexToApproved[_tokenId] = _approved;
    }
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        //require(_to != address(saleAuction));
        //require(_to != address(siringAuction));
      require(_owns(msg.sender, _tokenId));
        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        _transfer(_from, _to, _tokenId);
    }
    function totalSupply() public view returns (uint) {
        return Cards.length - 1;
    }

    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = CardIndexToOwner[_tokenId];

        require(owner != address(0));
    }
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 catId;

            for (catId = 1; catId <= totalCats; catId++) {
                if (CardIndexToOwner[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}










contract Exchange{
  ERC721 public nonFungibleContract;
}

contract ClockAuctionBase {

    struct Auction {
        address seller;
        uint256 startingPrice;
        uint256 endingPrice;
        uint64 Step;
        uint64 startedAt;
        uint32 maxTimes;
        address currentBuyer;
    }

    ERC721 public nonFungibleContract;

    uint256 public ownerCut;
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transfer(_receiver, _tokenId);
    }
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;   //给该拍卖编号

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }
    function _bid(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        uint256 price = auction.endingPrice;

        if(_bidAmount > price){
            address seller = auction.seller;
            _removeAuction(_tokenId);

            if (price > 0) {
                uint256 sellerProceeds = price ;


                seller.transfer(sellerProceeds);
                AuctionSuccessful(_tokenId, price, msg.sender);
            }


        }else{
            if(_bidAmount > auction.currentHighestBid){
                tokenIdToAuction[_tokenId].currentHighestBid = _bidAmount;
                tokenIdToAuction[_tokenId].currentBuyer = msg.sender;
            }
        }
        require(_bidAmount > price);  //需要拍卖结束
        return price;
    }
    function _closeAuction(uint256 _tokenId, bool agreeDeal)public{
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(!_isOnAuction(auction));         //已结束
        require(msg.sender==auction.seller);    //只限卖家操作

        //同意交易
        if(agreeDeal){
            uint256 price = auction.currentHighestBid;
            if (price > 0) {

                uint256 auctioneerCut = _computeCut(price);
                uint256 sellerProceeds = price - auctioneerCut;


                auction.seller.transfer(sellerProceeds);




                // 事件记录，拍卖成功
                AuctionSuccessful(_tokenId, price, auction.currentBuyer);

            }



        }
        _removeAuction(_tokenId);

    }



    ///  删除该拍卖
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// 判断该拍卖是否还继续
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// 计算卖家得到出价的利润
    function _computeCut(uint256 _price) internal view returns (uint256) {

        return _price * ownerCut / 10000;
    }

}



contract ClockAuction is ClockAuctionBase {
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);
    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            uint64(0),
            _seller
        );
        _addAuction(_tokenId, auction);
    }
    function bid(uint256 _tokenId)
    external
    payable
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }
    function cancelAuctionWhenPaused(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function createAuction



    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        uint256  currentHighestBid,
        address currentBuyer
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.startedAt,
        auction.currentHighestBid,
        auction.currentBuyer
        );
    }



}


///  卖出
contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;


    // Delegate constructor
    function SaleClockAuction(address _nftAddr, uint256 _cut) public
    ClockAuction(_nftAddr, _cut) {}

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            uint64(0),
            _seller
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId)
    external
    payable
    {
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    function closeAuction(bool agreed,uint256 tokenId) public{
        _closeAuction(tokenId,agreed);
    }

}
