//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Dreidel is Ownable {

    /** types */

    using SafeMath for uint256;

    enum Game_Status {
        LIVE,
        PENDING,
        OVER
    }

    struct Game {
        uint pot;
        uint anti;
        uint turn;
        uint member_limit;
        uint idle_time;
        Game_Status status;
        address payable[] members;
    }

    /** events */

    event Game_Proposed(Game game, address proposed_by);
    event Game_Joined(Game game, address joiner);
    event Game_Left(Game game, address departed);
    event Game_started(Game game, address started_by);
    event Anti_Taken(uint pot);
    event Spin(address from, uint spin_result, uint turn);
    event Member_Booted(address from, address booted, uint pot);

    /** declarations */

    mapping (address => uint) public member_buyin;

    Game[] public games;
    uint private _spin_nonce;
    uint idle_limit = 10 minutes;


    constructor() {
    }

    /** public functions */

    function propose_game(uint anti, uint member_limit) public payable returns (uint) {
        Game memory game = Game(
            0 ether,
            anti,
            0,
            member_limit, 
            block.timestamp,
            Game_Status.PENDING,
            new address payable[](0)
        );

        games.push(game);
        emit Game_Proposed(game, msg.sender);
        uint id = games.length - 1;
        join_game(id);

        return id;
    }

    function join_game(uint game_id) public payable {
        Game storage game = games[game_id];

        require(_game_status(game, Game_Status.PENDING));
        require(!_reached_member_limit(game));
        require(!_already_a_member(game));
        require(_has_enough_buyin(game));

        game.members.push(payable(msg.sender));
        member_buyin[msg.sender] = msg.value;

        emit Game_Joined(game, msg.sender);

        if (_reached_member_limit(game)) {
            _start_game(game);
        }
    }

    function get_game_members(uint game_id) public view returns (address payable[] memory) {
        return games[game_id].members;
    }

    function spin(uint game_id) public{
        Game storage game = games[game_id];
        require(_game_status(game, Game_Status.LIVE));
        require(uint(_member_id(game)) == game.turn);
        require(member_buyin[msg.sender] >= game.anti * 2);

        uint random_number = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _spin_nonce))) % 4;
        _spin_nonce++;

        if (random_number == 1) {
            member_buyin[msg.sender] += game.pot;
            game.pot = 0 ether;
            _take_anti(game);
        } else if (random_number == 2) {
            member_buyin[msg.sender] += game.pot / 2;
            game.pot = game.pot / 2;
        } else if (random_number == 3) {
            member_buyin[msg.sender] -= game.anti * 2;
            game.pot += game.anti * 2;
        }

        _increment_turn(game);

        emit Spin(msg.sender, random_number, game.turn);
    }

    function buyin() public payable {
        member_buyin[msg.sender] += msg.value;
    }

    function boot_member(uint game_id) public {
        Game storage game = games[game_id];
        require(block.timestamp - game.idle_time >  idle_limit, "Not enough time has elapsed");
        require(_already_a_member(game), "Not a game member");

        
        game.pot += member_buyin[game.members[game.turn]];
        emit Member_Booted(
            game.members[uint(_member_id(game))],
            game.members[game.turn],
            game.pot
        );
        delete member_buyin[game.members[game.turn]];
        delete game.members[game.turn];
        _increment_turn(game);
    }
    
    function leave_game(uint game_id) public {
        Game storage game = games[game_id];
        require(_game_status(game, Game_Status.LIVE));
        for (uint i=0; i < game.members.length - 1; i++) {
            if (game.members[i] == msg.sender) {
                payable(msg.sender).transfer(member_buyin[msg.sender]);
                delete member_buyin[msg.sender];
                delete game.members[i];
            }
        }
        emit Game_Left(game, msg.sender);
        if (game.members.length == 0) {
            game.status = Game_Status.OVER;
            payable(owner()).transfer(game.pot);
        }
    }


    /** private functions */

    function _start_game(Game storage game) internal {
        require (_reached_member_limit(game));
        game.status = Game_Status.LIVE;
        game.idle_time = block.timestamp;
        emit Game_started(game, msg.sender);
        _take_anti(game);
    }

    /** helper functions */

    function _has_enough_buyin(Game memory game) internal view returns (bool) {
        return (msg.value > ((game.anti * game.member_limit) + (game.anti * 3)));
    }

    function _already_a_member(Game memory game) internal view returns (bool) {
        for (uint i=0; i < game.members.length; i++) {
            if (game.members[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _reached_member_limit(Game memory game) internal pure returns (bool) {
        return game.members.length >= game.member_limit;
    }

    function _game_status(Game memory game, Game_Status status) internal pure returns (bool) {
        return game.status == status;
    }

    function _increment_turn(Game storage game) internal {
        if (game.turn == game.members.length - 1) {
            game.turn = 0;
        } else {
            game.turn++;
        }

        game.idle_time = block.timestamp;
    }

    function _take_anti(Game storage game) internal {
            for (uint i = 0; i < game.members.length; i++) {
                member_buyin[game.members[i]] = member_buyin[game.members[i]] - game.anti;
            }
            game.pot = game.anti * game.members.length;
            emit Anti_Taken(game.pot);
    }

    function _member_id(Game memory game) internal view returns (int) {
        for (uint i = 0; i < game.members.length; i++) {
            if (game.members[i] == msg.sender) {
                return int(i);
            }
        }
        return -1;
    }

}
