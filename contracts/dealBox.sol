//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interface/IBlindBox.sol";
import "./interface/ISLM20.sol";

contract DealBox is Ownable, Pausable {
    using SafeMath for uint256;

    IBlindBox public BlindBox;
    ISLM20 public SLM;

    address payable public payee;
    string public baseURI;

    uint256 public SLMRate = 1000;
    uint256 public referrerRate = 10;

    mapping(uint => Box) public BoxMap;

    event Buy(address indexed sender, uint indexed id, uint indexed num);

    struct Box {
        uint    id;
        string  name;
        uint    price;
        uint256 mintNum;
        uint256 totalSupply;
        bool    status;
    }

    constructor() {
        BlindBox = IBlindBox(0x1db9EB7e514069908D131A150a629E66e2eFd444);
        SLM = ISLM20(0x2e9c1d9346D399c63e02Ae82158c6c554C1755EF);
        payee = payable(msg.sender);
    }

    function newBox(uint boxID_, uint price_, string memory name_, uint256 totalSupply_, bool status_) public onlyOwner {
        require(BoxMap[boxID_].id == 0, "boxID err or boxID already exist");
        BoxMap[boxID_] = Box({
            id: boxID_,
            name: name_,
            price: price_,
            mintNum: 0,
            totalSupply: totalSupply_,
            status: status_
        });
    }

    function editBox(uint boxID_, uint price_, uint256 totalSupply_) public onlyOwner {
        require(BoxMap[boxID_].id != 0, "boxID err");
        BoxMap[boxID_] = Box({
            id: boxID_,
            name: BoxMap[boxID_].name,
            price: price_,
            mintNum: BoxMap[boxID_].mintNum,
            totalSupply: totalSupply_,
            status: BoxMap[boxID_].status
        });
    }

    function buyBox(uint boxID_, uint num_, address payable referrer) public payable whenNotPaused {
        require(BoxMap[boxID_].id != 0, "box id err");
        require(BoxMap[boxID_].status, "box is off");
        require(BoxMap[boxID_].totalSupply >= BoxMap[boxID_].mintNum + num_, "Sold out");
        require(msg.value >= num_.mul(BoxMap[boxID_].price), "Invalid price");
        BoxMap[boxID_].mintNum += num_;
        // BNB or ETH is 18 decimal, SLM token is 6 decimal, 12 = 18 - 6
        uint256 slmToken = msg.value.mul(SLMRate).div(10 ** 12);

        if (referrer == address(0) || referrerRate == 0) {
            payee.transfer(msg.value);
        } else {
            uint256 referrerAmount = msg.value.mul(referrerRate).div(100);
            require(msg.value == referrerAmount.add(msg.value.sub(referrerAmount)), "transfer amount err");
            referrer.transfer(referrerAmount);
            payee.transfer(msg.value.sub(referrerAmount));
        }

        SLM.mint(_msgSender(), slmToken);
        BlindBox.mint(_msgSender(), boxID_, num_);
        emit Buy(_msgSender(), boxID_, num_);
    }

    function setStatus(uint id, bool status_) public onlyOwner {
        BoxMap[id].status = status_;
    }

    function setPayee(address payable payee_) public onlyOwner {
        payee = payee_;
    }

    function setPause(bool isPause) public onlyOwner {
        if (isPause) {
            _pause();
        } else {
            _unpause();
        }
    }
    function withdraw() public payable onlyOwner {
        payee.transfer(address(this).balance);

    }

    function setSLMRate(uint256 rate_) public onlyOwner {
        SLMRate = rate_;
    }

    function setReferrerRate(uint256 referrerRate_) public onlyOwner {
        require(referrerRate_ <= 100, "err: rate > 100");
        referrerRate = referrerRate_;
    }

    function setURI(string memory uri_) public onlyOwner {
        baseURI = uri_;
    }
}
