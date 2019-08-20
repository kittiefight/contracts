## Using scripts

1. Deploy game to Ganache
    ```truffle migrate --reset```

After this go to scripts/FE and follow steps:

2. Register users to the system (1-39)

    ```truffle exec scripts/FE/registerUsers.js noOfUsers```

3. Sent KTY tokens to users (1-39) and amount (i.e. 5000 KTY) and approve that amount to endowment contract

    ```truffle exec scripts/FE/sendKTY.js noOfUsers amountOfKTY```

4. Mint kitties and approve them to kittie Hell contract (# users is 1 to max 8). This will also verify civic id

    ```truffle exec scripts/FE/prepare_environment.js noOfUsers``` 

5. Create a new game (manual match) For the time format for start game should be like the next line example

    ```truffle exec scripts/FE/newGame.js kitty1 kitty2 "2019-08-19 21:10:30"``` 

6. Make users participate and choose a corner, time in seconds

    ```truffle exec scripts/FE/participare.js gameId noOfSupportersBlack noOfSupportersRed timeBetweenParticipating```

7. Make both players in the game press start button

    ```truffle exec scripts/FE/pressStart.js gameId```

8. will continue... (edited)