# Draconic Reactor PID Control FAQ  
  
### Q:How to Use?  
- Download reactorv2.lua and put it on your OC computer which already connected to screen,GPU,2xFlux Gate and a reactor  
- Enter `edit reactorv2.lua` and make sure the component addresses are correct
- Ctrl+W quit edit mode and run `reactorv2` to start program, the program will automaticly initialize the reactor
### Q:Can I Configure the Arguments of PID?
- Yes.
- To do this, enter edit mode and you can see the variables `setTemp` `setfield` `fieldCoe` `tempCoe` `energyCoe` `intgTime` `autoStop`
- `setTemp` : target temperature (in °C)
- `setfield` : target field (in %,which mean value range is between 0 and 1)
- `*Coe` : PID arguments (Kp Ki Kd in order)
- `intgTime` : integration time (in cycle times)
### Q:Do the Program Blow up My Reactor?
- Maybe.
- Although the program ***Has*** an auto emergency stop to prevent some accident happening
- If your argument is ***Really*** go beyond what is proper,the program will unable to react that fast to stop reactor and it will BOOM!
- **So If You Don't Know What You're Doing, Don't Touch Anything**
### Q:Can I Bypass The Auto Emergency Stop?
- Yes.
- However testing new arguments without AES's protect can easily make your reactor a huge firework
- To disable AES, add `overClock=true` to the top of program
- When you start program with that,screen will warn you the AES was disabled 
