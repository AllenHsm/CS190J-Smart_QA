// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.1;

contract Queue {
    mapping (uint256 => uint256)  queue;
    uint256 first = 1;
    uint256 last = 0;
    function enqueue(uint256 data) public {
        last += 1;
        queue[last] = data;
    }

    function dequeue() public returns (uint256) {
        uint256 data;
        require(last >= first);
        data = queue[first];
        delete queue[first];
        first += 1;
        return data;
    }
    function length() public view returns (uint256) {
        return last+1 - first;
    }
    function sqr_sum() public view returns (uint256 sum){
        sum = 0;
        for (uint256 i = first; i < last+1; i++){
            sum += queue[i] * queue[i];
        }
        return sum;
    }
}