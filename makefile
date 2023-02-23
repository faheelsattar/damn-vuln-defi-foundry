Unstoppable: 
	forge test --match-test testExploit --match-contract Unstoppable

NaiveReceiver:
	forge test --match-test testExploit --match-contract NaiveReceiver

Truster:
	forge test --match-test testExploit --match-contract Truster
	
SideEntrance:
	forge test --match-test testExploit --match-contract SideEntrance
	
TheRewarder:
	forge test --match-test testExploit --match-contract TheRewarder

Selfie:
	forge test --match-test testExploit --match-contract Selfie

Compromised:
	forge test --match-test testExploit --match-contract Compromised

Puppet:
	forge test --match-test testExploit --match-contract Puppet$

PuppetV2:
	forge test --match-test testExploit --match-contract PuppetV2

PuppetV3:
	forge test --match-test testExploit --match-contract PuppetV3 --fork-url $(forkurl) --fork-block-number $(forkblock)

FreeRider:
	forge test --match-test testExploit --match-contract FreeRider

Backdoor:
	forge test --match-test testExploit --match-contract Backdoor

Climber:
	forge test --match-test testExploit --match-contract Climber

SafeMiners:
	forge test --match-test testExploit --match-contract SafeMiners

