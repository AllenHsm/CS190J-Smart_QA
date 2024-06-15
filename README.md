# SmartQ&A
## Overview


SmartQ&A is a blockchain based question and answering platform that allows users to engage in interactive knowledge sharing where they can post question and earn ETH with good answers. In this project, we utilize `solidity 0.8.1` to achieve following features:

- User Registration
- Question Asking
- Answer Posting
- Answer Endorsement
- Adward Distribution


## Team Members
- James Pflaging
- Ray Du
- Allen Hu
- Zixiao Jin



## Framework
![screenshot](assets/framework.png)


## Installation

Clone and run it on [Remix](remix.ethereum.org). 

## Run the tests locally

```sh
forge build
forge test -vvv
```
# Introduction to Smart Q&A
## What users can do
- Ask and answer questions
- Set Ethereum reward for good answers
- Endorse other users' answer
## Ask Questions
To ask questions, you first need to register with a personal user name that can be seen by others. Then put in your question, set expiration time and amount of reward. Make sure the wallet you used to register have enough balance as you need to deposit the reward when the question is posted. But don't worry, if unfortunately, you do not get any satisfactory answers, you are free to close the question and get your money back before the expiration time. \
However, there is a upper bound, 0.01 Ethereum, for the maximum reward a new user can set. Every time you choose to or not to give out the reward will affect your credit history. The more reward you give out, the higher amount you can set in the future. If you want to send the reward to a specific answerer, you need to choose it as the best answer before you close the question. Otherwise, by the time question expires, the reward will be automatically sent to the user whose answer get most endorsement. 