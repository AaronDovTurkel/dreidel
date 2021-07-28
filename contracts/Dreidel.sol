//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Dreidel is Ownable {

    using SafeMath for uint256;

    enum Spin_Results {
        GIMEL,
        HEI,
        NUN,
        SHIN
    }

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

    mapping (address => uint) member_buyin;

    Game[] games;
    uint private _spin_nonce;
    uint idle_limit = 10 minutes;


    constructor() {
    }

    /** public functions */

    function list_games() public view returns (Game[] memory) {
        return games;
    }

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

        if (_reached_member_limit(game)) {
            _start_game(game);
        }
    }

    function spin(uint game_id) public returns (Spin_Results, uint) {
        Game storage game = games[game_id];
        require(_game_status(game, Game_Status.LIVE));
        require(_member_id(game) == game.turn);
        require(member_buyin[msg.sender] >= game.anti * 2);

        uint random_number = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _spin_nonce))) % 4;
        _spin_nonce++;
        Spin_Results spin_result = Spin_Results(random_number);

        if (spin_result == Spin_Results.GIMEL) {
            member_buyin[msg.sender] += game.pot;
            _take_anti(game);
        } else if (spin_result == Spin_Results.HEI) {
            member_buyin[msg.sender] += game.pot / 2;
        } else if (spin_result == Spin_Results.SHIN) {
            member_buyin[msg.sender] -= game.anti * 2;
            game.pot += game.anti * 2;
        }

        _increment_turn(game);

        return (spin_result, game.turn);
    }

    function boot_member(uint game_id) public {
        Game memory game = games[game_id];
        require(game.idle_time > block.timestamp - idle_limit);
        require(_already_a_member(game));

        game.pot += member_buyin[game.members[_member_id(game)]];
        delete member_buyin[game.members[_member_id(game)]];
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
        if (game.members.length == 0) {
            game.status = Game_Status.OVER;
        }
    }


    /** private functions */

    function _start_game(Game storage game) internal {
        require (_reached_member_limit(game));
        game.status = Game_Status.LIVE;
        game.idle_time = block.timestamp;
        _take_anti(game);
    }

    /** helper functions */

    function _has_enough_buyin(Game memory game) internal view returns (bool) {
        return (msg.value > ((game.anti * game.member_limit) + (game.anti * 3)));
    }

    function _already_a_member(Game memory game) internal view returns (bool) {
        bool member = false;
        for (uint i=0; i < game.members.length; i++) {
            member = game.members[i] == msg.sender;
        }
        return member;
    }

    function _reached_member_limit(Game memory game) internal pure returns (bool) {
        return game.members.length >= game.member_limit;
    }

    function _game_status(Game memory game, Game_Status status) internal pure returns (bool) {
        return game.status == status;
    }

    function _increment_turn(Game memory game) internal view {
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
    }

    function _member_id(Game memory game) internal view returns (uint) {
        uint member_id;
        for (uint i = 0; i < game.members.length - 1; i++) {
            if (game.members[i] == msg.sender) {
                member_id = i;
            }
        }
        return member_id;
    }

}
