#Antonino Febbraro
#adf47@pitt.edu
#Project 1 -- "Bugs"
#Due March 18,2016


#NOTES
	#1=blaster move
	# >3 is parts of the wave

.data
ending: .asciiz "The game score is "
ending2: .asciiz ": "
player: .byte 32,63,2 #stores position of player 
blaster: .byte 0,62,1 # stores position of newly fired pulse.
gameQue: .word 0:256000
numOfEventsQue: .word 0:1
pulseQue: .word 0:128000

.text
la $s0, gameQue 
move $s1, $s0 
la $s4,pulseQue
li $t9,0
li $s7,1 #for deciding how many bugs to make
#Setting up the START of the game

#ALLOWING THE PLAYER TO MOVE!

poll: 	beqz $t9,keys
	
	li $v0,30
	syscall 
	move $t1,$a0
	
	#checking for the end of the game 
	sub $t3,$t1,$a3
	bge $t3,120000,gameOver #2 min timer
	
	delay:  bge $t2,100,con
		li $v0,30
		syscall
		sub $t2,$a0,$t1
		j delay
	con:
	jal MakeBugs #makes new bugs
	jal animate  #animates the game
	jal collison #CHECKS FOR collisons
	
keys:   	#the keyboard controls
	la	$v0,0xffff0000		# address for reading key press status
	lw	$t6,0($v0)		# read the key press status
	andi	$t6,$t6,1
	beq	$t6,$0,poll		# no key pressed
	lw	$t6,4($v0)		# read key value
	
		     								     						
lkey:	addi	$v0,$t6,-226		# check for left key press
	bne	$v0,$0,rkey		# wasn't left key, so try right key
	lb $a0,player+0
	lb $a1,player+1
	beqz $a0,poll
	li $a2,0
	jal setLED
	li $a2,2
	addi	$a0,$a0,-1		# change position of player to the left
	sb $a0,player+0			# argument for call
	jal	setLED			# redraw box in new color
	j poll
rkey:	addi	$v0,$t6,-227		# check for right key press
	bne	$v0,$0,upkey		# wasn't right key, so check for center
	lb $a0,player+0
	lb $a1,player+1
	beq $a0,63,poll
	li $a2,0
	jal setLED
	li $a2,2
	addi	$a0,$a0,1		# change position of player to the left
	sb $a0,player+0			# argument for call
	jal	setLED		# redraw box in new color
	j	poll
	
upkey: 	addi	$v0,$t6,-224		# check for right key press
	bne	$v0,$0,downkey		# wasn't right key, so check for center
	#lb	$t5,player+0		# change position of player to the up
	lb 	$a0,player+0 		#loading in the x coordinate 
	#add 	$a0,$a0,$t5
	li $a1,62
	li $a2,1 #stores the color
	jal insert_q
	jal insertPulse
	addi $s2,$s2,1 # to count the number of phaser-firings
	j poll
	
downkey:addi	$v0,$t6,-225		# check for center key press
	bne	$v0,$0,bkey
	j gameOver
	
bkey:	addi	$v0,$t6,-66		# check for center key press
	bne	$v0,$0,poll		# invalid key, ignore it
	li $t9,1
	li $v0,30
	syscall
	move $a3,$a0
	lb $a1,player+1
	lb $a0,player+0
	lb $a2,player+2
	jal setLED
	##Adding three random placed bugs to start the game
	li $t0,0
	beg: 
	beq $t0,3,fin
	li $v0,42
	li $a1,64
	syscall
	li $a1,1
	li $a2,3
	jal insert_q
	addi $t0,$t0,1
	j beg
	fin:
	j poll

insert_q:
	#this inserts an event into the queue
	sb $a0, 0($s1) #read README about this line, not used in code
	sb $a0, 1($s1) #x
	sb $a1, 2($s1) #y
	sb $a2, 3($s1) # type/color
	sb $a3, 4($s1)
	addi $sp, $sp, -12
	sw $ra, 0($sp) 
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	la $t0, numOfEventsQue
	lw $t1, 0($t0)
	addi $t1, $t1, 1 #num of events
	sw $t1, 0($t0)
	addi $s1, $s1, 8
	li $t0, 0x10010050 #to change to front 
	bne $s1, $t0, end_insert
	li $s1, 0x10010000 
	end_insert:
	lw $t1, 8($sp)
	lw $t0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 12
	jr $ra	

insertPulse:
	#8 offset from tail
	sb $t0, 0($s4) #again, read README about this line it is not used
	sb $a0, 1($s4) #x
	sb $a1, 2($s4) #y
	sb $a2, 3($s4) #type/color
	sb $a3, 4($s4) #rbeginning of program
	addi $s4,$s4,5
	addi $s5,$s5,1 #updating number of pulses in the queue
	jr $ra		
						
	
size_q: #fucntion for getting the number of events inside the queue 
	addi $sp, $sp, -8
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	la $t0, numOfEventsQue
	lw $t1, 0($t0)
	move $v0, $t1
	lw $t1, 4($sp)
	lw $t0, 0($sp)
	addi $sp, $sp, 8
	jr $ra	

	
remove_q: #this removes an event from the queue 
	addi $sp, $sp, -5
	lb $t2, 0($s0) 
	sb $t2, 0($sp) #again, read README, line not used
    	lb $t2, 1($s0) #x
    	sb $t2, 1($sp) 
    	lb $t2, 2($s0) #y
    	sb $t2, 2($sp)
    	lb $t2, 3($s0) #type/color
    	sb $t2, 3($sp)
    	lb $t2, 4($s0) 
    	sb $t2, 4($sp)
    	li $t2, 0
    	sw $t2, 0($s0) 
    	sw $t2, 4($s0) 
    	la $t7, numOfEventsQue
	lw $t8, 0($t7)
	addi $t8, $t8, -1 #update num events 
	sw $t8, 0($t7)
	addi $s0, $s0, 8 
    	jr $ra

setLED:
#arguments: $a0 is x, $a1 is y, $a2 is color
# byte offset into display = y * 16 bytes + (x / 4)

sll $t0,$a1,4
srl $t1,$a0,2
add $t0,$t0,$t1
li $t2,0xffff0008 
add $t0,$t2,$t0
# y * 16 bytes
# x / 4
# byte offset into display
# base address of LED display # address of byte with the LED
# now, compute led position in the byte and the mask for it
andi $t1,$a0,0x3 
neg $t1,$t1 
addi $t1,$t1,3 
sll $t1,$t1,1
# remainder is led position in byte # negate position for subtraction
# bit positions in reverse order #ledis2bits
# compute two masks: one to clear field, one to set new color
li $t2,3
sllv $t2,$t2,$t1
not $t2,$t2 
sllv $t1,$a2,$t1 # get current LED 
lbu $t3,0($t0) 
and $t3,$t3,$t2 
or $t3,$t3,$t1 
sb $t3,0($t0) 
jr $ra



#   returns the value of the LED at position (x,y)
#  arguments: $a0 holds x, $a1 holds y
#  trashes:   $t0-$t2
#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)

getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra

#NOTE: slow down the pace...onyl 3-4 at a time
MakeBugs:  move $s3,$ra 
	   li $v0,42 #generating random bug here
	   li $a1,63
	   syscall
	   move $t1,$a0
	   li $a1,1
	   li $a2,3
	   slti $t2,$s7,920 #to make game harder at the end by making more bugs
	   beq $t2,1,draw
	   jal insert_q
	   j returns
	   draw:
	   li $v0,42
	   li $a1,10 ## making a random choice weather to place or not 50/50 chance
	   syscall
	   beq $a0,5,make
	   j returns
	   make:
	   move $a0,$t1
	   li $a1,1
	   li $a2,3
	   jal insert_q
	   returns:
	   addi $s7,$s7,1
	   jr $s3
	   
animate:  move $s3,$ra
	  jal size_q
	  move $s6,$v0
	  #move $s4,$s6
	  la $s4,pulseQue
	  li $s5,0
	  li $t4,0
	  loop:
	  	beq $t4,$s6,end
	  	jal remove_q
	  	lb $t0, 0($sp)
    		lb $a0, 1($sp)
    		lb $a1, 2($sp)
    		lb $a2, 3($sp)
    		lb $t2, 4($sp)
    		addi $sp, $sp, 5
    		addi $t4,$t4,1
    		beq $a2,1,pulse
    		beq $a2,3,bugs
    		bgt $a2,3 waves
    		conAnimate:
    			j loop
	  end:	
	  	jr $s3	   				

pulse:	li $a2,0
	jal setLED
	beq $a1,0,conAnimate
	addi $a1,$a1,-1
	li $a2,1
	jal insert_q
	jal insertPulse
	jal setLED
	j conAnimate


bugs:	li $a2,0
	jal setLED
	beq $a1,62,conAnimate 
	addi $a1,$a1,1
	jal getLED
	beq $v0,1,collided #so that bug does not go over a pulse
	li $a2,3
	jal insert_q
	jal setLED
	j conAnimate
	
waves:	
	beq $a1,63,conZero
	beq $a1,0,conZero	
	beq $a0,0,conZero
	beq $a0,63,conZero
	beq $a2,4,leftup
	beq $a2,5,leftdown
	beq $a2,6,rightup
	beq $a2,7,rightdown
	beq $a2,8,left
	beq $a2,9,right
	beq $a2,10,down
	beq $a2,11,up
	
	conZero:
		li $a2,0
		jal setLED
		j conAnimate
		
	right:  li $a2,0
		jal setLED
		addi $a0,$a0,1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,9
		jal insert_q
		j conAnimate
	
	left:  li $a2,0
		jal setLED
		addi $a0,$a0,-1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,8
		jal insert_q
		j conAnimate
	
	down:	li $a2,0
		jal setLED
		addi $a1,$a1,1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,10
		jal insert_q
		j conAnimate
		
	up:	li $a2,0
		jal setLED
		addi $a1,$a1,-1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,11
		jal insert_q
		j conAnimate	
			
	
	leftup: li $a2,0
		jal setLED
		addi $a0,$a0,-1
		addi $a1,$a1,1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,4
		jal insert_q
		j conAnimate
		
	leftdown: li $a2,0
		jal setLED
		addi $a0,$a0,-1
		addi $a1,$a1,-1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,5
		jal insert_q
		j conAnimate
		
	rightup: li $a2,0
		jal setLED
		addi $a0,$a0,1
		addi $a1,$a1,1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,6
		jal insert_q
		j conAnimate
		
	rightdown: li $a2,0
		jal setLED
		addi $a0,$a0,1
		addi $a1,$a1,-1
		li $a2,1
		jal setLED
		jal insertPulse
		li $a2,7
		jal insert_q
		j conAnimate			
	
collison: move $s3,$ra
	  jal size_q
	  li $t4,0
	  li $t7,0 #boolean for collison
	  move $k0,$v0
	  loop1:
	  	beq $t4,$k0,end2
	  	jal remove_q
	  	lb $t3, 0($sp)
    		lb $a0, 1($sp)#x
    		lb $a1, 2($sp)#y
    		lb $a2, 3($sp)#color
    		lb $t2, 4($sp)
    		addi $sp, $sp, 5
    		addi $t4,$t4,1
    		beq $a2,3,checkCollison #bug/green
    		beq $a2,0,checkCollison # for if it is turned off
    		conAnimate2:
    			beq $t7,100,loop1
    			jal insert_q
    			j loop1
  
	  end2:	
	  	jr $s3		  	
	  	
checkCollison: 	 li $t5,0
		 #move $s4,$s6
		 la $s4,pulseQue
		 
		 loop2:	
		 	 beq $t5,$s5,conAnimate2
		 	 lb $t0,1($s4) #x
		 	 lb $t1,2($s4) #y		
		 	 beq $t0,$a0,checky #x
		 	 j endl2
		 	 checky:
		 	 	beq $t1,$a1,remove	#y
		 	 endl2:	
		 	 	addi $t5,$t5,1
		 	 	addi $s4,$s4,5
		 	 	j loop2
		 	 	
remove:	#turn off the blaster
	#move $a0,$t0
	#move $a1,$t1
	li $a2,0
	jal setLED
	li $t7,100 #boolean for if collided
	#add wave to queue here!
	li $a2,4
	jal insert_q
	li $a2,5
	jal insert_q
	li $a2,6
	jal insert_q
	li $a2,7
	jal insert_q
	li $a2,8
	jal insert_q
	li $a2,9
	jal insert_q
	li $a2,10
	jal insert_q
	li $a2,11
	jal insert_q
	
	addi $v1,$v1,1 #score!!
	j conAnimate2
	
#For special cases of when bug goes over a pulse	

collided:
	#add wave to queue here!
	li $a2,4
	jal insert_q
	li $a2,5
	jal insert_q
	li $a2,6
	jal insert_q
	li $a2,7
	jal insert_q
	li $a2,8
	jal insert_q
	li $a2,9
	jal insert_q
	li $a2,10
	jal insert_q
	li $a2,11
	jal insert_q
	
	addi $v1,$v1,1 #score!!	
	j conAnimate		 	 		   			   				   			   						 	 		   			   				   			   			
	 	
#function for ending the game when user presses down arrow or after 2 mins is up	 	
gameOver: la $a0,ending
	  li $v0,4
	  syscall
	  move $a0,$v1 #printing the bug hits
	  li $v0,1
	  syscall 
	  la $a0,ending2
	  li $v0,4
	  syscall
	  move $a0,$s2 #printing the phaser-firings
	  li $v0,1
	  syscall
	  li $v0,10
	  syscall
