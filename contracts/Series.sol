// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Series is Ownable {
  string public title;
  uint public pledgePerEpisode;
  uint public minimumPublicationPeriod;

  mapping(address => uint) public pledges;
  address[] pledgers;
  uint public lastPublicatioinBlock;
  mapping(uint => string) public publishedEpisodes;
  uint public episodeCounter;

  constructor(string _title, uint _pledgePerEpisode, uint _minimumPublicationPeriod) public {
    title = _title;
    pledgePerEpisode = _pledgePerEpisode;
    minimumPublicationPeriod = _minimumPublicationPeriod;
  }

  function pledge() public payable {
    require(pledges[msg.sender].add(msg.value) >= pledgePerEpisode, "Pledge must be greater thank minimum amount");
    require(msg.sender != owner, "Owner cannot pledge on his own series");

    bool oldPledger = false;
    for(uint i = 0; i < pledgers.length; i++) {
      if (pledgers[i] == msg.sender) {
        oldPledger = true;
        break;
      }
    }
    if (!oldPledger) {
      pledgers.push(msg.sender);
    }

    pledges[msg.sender] = pledges[msg.sender].add(msg.value);
  }

  function withdraw() public {
    uint amount = pledges[msg.sender];
    if (amount > 0) {
      pledges[msg.sender] = 0;
      msg.sender.transfer(amount);
    }
  }

  function publish(string episodeLink) public onlyOwner {
    require(lastPublicatoinBlock == 0 || block.number > lastPublicationBlock.add(minimumPublicationPerEpisode), "Owner cannot publish again so soon");
    
    lastPublicatioinBlock = block.number;
    episodeCounter++;
    publishedEpisodes[episodeCounter] = episodeLink;

    unit episodePay = 0;
    for (uint i = 0; i < pledgers.length; i++) {
      if (pledges[pledgers[i]] >= pledgePerEpisode) {
        pledges[pledgers[i]] = pledges[pledgers[i]].sub(pledgePerEpisode);
        episodePay = episodePay.add(pledgePerEpisode);
      }
    }

    owner.transfer(episodePay);
  }
  
  function close() public onlyOwner {
    for (uint i = 0; i < pledges.length; i ++) {
      uint amount = pledges[pledgers[i]];
      if (amount > 0) {
        pledgers[i].transfer(amount);
      }
    }
    selfdestruct(owner);
  }

  function totalPledgers() public view returns(uint) {
    return pledgers.length;
  }
  function activePledgers() public view returns(uint) {
    uint active = 0;
    for(uint i = 0; i < pledgers.length; i ++) {
      if (pledges[pledgers[i]] >= pledgePerEpisode) {
        active++;
      }
    }
    return active;
  }

  function nextEpisodePay() public view returns(uint) {
    uint episodePay = 0;
    for(uint i = 0; i < pledgers.length; i++) {
      if (pledges[pledgers[i]] >= pledgePerEpisode) {
        episodePay = episodePay.add(pledgePerEpisode);
      }
    }
    return episodePay;
  }
}
