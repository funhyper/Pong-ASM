IDEAL
MODEL small
STACK 100h
boardWidth equ 320
boardHeight equ 200
scoreToWin equ 3
colorWhite equ 15 ; Code for the color white https://en.wikipedia.org/wiki/BIOS_color_attributes
colorBlack equ 0 
paddleHeight equ 50
paddlewidth equ 8
paddleDistanceFromWidthWall  equ 4
paddleDistanceFromHeightWall equ 75
ballSize equ 6
clock equ es:6Ch
scoreBoardWidth equ 80 ; When using int 10h there is diffrent width and height to the screen
scoreBoardHeight equ 25
numOfSoundTicks equ 3
DATASEG
	; Ball coordinates are the most left and high corner
	ball_x dw ? 
	ball_y dw ?
	ballSpeedX dw -5

	ballSpeedY dw 7
	saveSpeedY dw 7 ; This variable is keeping the original speed when the ball has to "break" when he hits the wall
	
	paddle1_x dw ?
	paddle1_y dw ?
	paddle2_x dw ?
	paddle2_y dw ?
	paddleSpeed dw 5
	;Score
	player1 db 0
	player2 db 0
	
	; Wall sound MS counter
	wallCounter db ?
	; Paddle sound MS counter
	paddleCounter db ?

	restartMsg db 'Would you like to restart the game? (y/n)', 10, 13, '$'
CODESEG
proc playWallSound
	; Function Plays a sound when ball hits the wall
	; Return: None
	; Params: None
	push ax
	in al, 61h
	or al, 00000011b
	out 61h, al
	mov al, 0B6h
	out 43h, al


	mov al, 98h
	out 42h, al ; Sending lower byte
	mov al, 0Ah
	out 42h, al ; Sending upper byte

	pop ax
	ret
endp playwallsound

proc playPaddleSound
	; Function Plays a sound when ball hits a paddle
	; Return: None
	; Params: None
	push ax
	in al, 61h
	or al, 00000011b
	out 61h, al
	mov al, 0B6h
	out 43h, al


	mov al, 98h
	out 42h, al ; Sending lower byte
	mov al, 08h
	out 42h, al ; Sending upper byte

	pop ax
	ret
endp playPaddleSound

proc stopSound
	push ax
	in al, 61h
	and al, 11111100b
	out 61h, al
	pop ax
	ret
endp stopsound

x1 equ [bp+4]
y1 equ [bp+6]
x2 equ [bp+8]
y2 equ [bp+10]
speedOrg equ [bp+12]
speed equ [bp-1]
proc moveObjectX
	; Function that moves an object on the X axis
	; Params: x1, y1, x2, y2, speed
	push bp
	mov bp, sp
	dec sp
	push ax

	mov ax, speedOrg ; It will be easier to handle the speed in memory becasue we may need to manipulate it
	mov speed, ax

	mov ax, 0
	cmp speed, ax ; Checks if the speed is negative
	; The idea of moving the object is that you make the left of the object (if we are moving right) black and the same amount you erased in the left
	; you draw new amount at the right and then you have the illusion of moving
	jg moveRight
	jmp moveLeft
moveRight:
	push colorblack
	mov ax, x2
	sub ax, x1 ; Getting the width of the ball
	cmp ax, speed ; This is for efficiency becasue we want to erase only the ball and not pixels that are already black
	ja deleteEverthingRight
	jmp deleteObjectRight
deleteEverthingRight:
	push y2
	mov ax, x1
	add ax, speed
	push ax
	push y1
	push x1
	call drawrectangle
	jmp createNewObjectRight
deleteObjectRight:
	push y2
	push x2
	push y1
	push x1
	call drawrectangle
createNewObjectRight:
	push colorwhite
	push y2
	mov ax, x2
	sub ax, x1
	add ax, speed
	add ax, x1
	push ax
	push y1
	mov ax, x1
	add ax, speed
	push ax
	call drawrectangle
	jmp endmoveobjectx

moveLeft: ; This is a mirror variation for the same thing, just moving left
	mov ax, speed
	neg ax
	mov speed, ax
	push colorblack
	mov ax, x2
	sub ax, x1
	cmp ax, speed 
	ja deleteEverthingLeft
	jmp deleteObjectLeft
deleteEverthingLeft:
	push y2
	push x2
	push y1
	mov ax, x2
	sub ax, speed
	push ax
	call drawrectangle
	jmp createNewObjectLeft
deleteObjectLeft:
	push y2
	push x2
	push y1
	push x1
	call drawrectangle
createNewObjectLeft:
	push colorwhite
	push y2
	mov ax, x2
	sub ax, speed
	push ax
	push y1
	mov ax, x1
	sub ax, x2
	add ax, x2
	sub ax, speed
	push ax
	call drawrectangle
endmoveObjectX:
	pop ax
	inc sp
	pop bp
	ret 10
endp moveObjectX


x1 equ [bp+4]
y1 equ [bp+6]
x2 equ [bp+8]
y2 equ [bp+10]
speedOrg equ [bp+12]
speed equ [bp-1]
proc moveObjectY
	; Function that moves an object on the Y axis. Same idea as the X axis, just Y
	; Params: x1, y1, x2, y2, speed
	push bp
	mov bp, sp
	dec sp
	push ax

	mov ax, speedOrg 
	mov speed, ax

	mov ax, 0
	cmp speed, ax ; Checks if the speed is negative

	jg moveDown
	jmp moveup
moveUp:
	mov ax, speed
	neg ax
	mov speed, ax
	push colorblack
	mov ax, y2
	sub ax, y1 ; Ax holds the height of the object 
	cmp ax, speed ; This is for efficiency becasue we want to erase only the ball and not pixels that are already black
	ja deleteEverthingUp
	jmp deleteObjectUp
deleteEverthingUp:
	push y2
	push x2
	mov ax, y2
	sub ax, speed
	push ax
	push x1
	call drawrectangle
	jmp createNewObjectUp
deleteObjectUp:
	push y2
	push x2
	push y1
	push x1
	call drawrectangle
createNewObjectUp:
	push colorwhite
	mov ax, y2
	sub ax, speed
	push ax
	push x2
	mov ax, y1
	sub ax, speed
	push ax
	push x1
	call drawrectangle
	jmp endmoveobjecty



moveDown:
	push colorblack
	mov ax, y2
	sub ax, y1 ; Ax holds the height of the object 
	cmp ax, speed ; This is for efficiency becasue we want to erase only the ball and not pixels that are already black
	ja deleteEverthingDown
	jmp deleteObjectDown
deleteEverthingDown:
	mov ax, y1
	add ax, speed
	push ax
	push x2
	push y1
	push x1
	call drawrectangle
	jmp createNewObjectDown
deleteObjectDown:
	push y2
	push x2
	push y1
	push x1
	call drawrectangle
createNewObjectDown:
	push colorwhite
	mov ax, y2
	add ax, speed
	push ax
	push x2
	mov ax, y1
	add ax, speed
	push ax
	push x1
	call drawrectangle
endmoveObjectY:
	pop ax
	inc sp
	pop bp
	ret 10
endp moveobjecty

proc drawBoard
	; Function draws the obejcts in the board and initializes the x and y coordinates of the ball and the paddles
	; Parmas: None
	; Return: None
	push ax
	push bx
	push cx
	; Draw right paddle
	push colorWhite
	mov ax, paddleDistanceFromHeightWall
	add ax, paddleHeight
	mov bx, paddleDistanceFromWidthWall
	add bx, paddlewidth
	push ax
	push bx
	push paddleDistanceFromHeightWall
	push paddleDistanceFromWidthWall
	call drawRectangle
	mov [paddle1_x], paddleDistanceFromWidthWall
	mov [paddle1_y], paddleDistanceFromHeightWall

	; Draw left paddle
	push colorWhite
	mov ax, boardHeight
	sub ax, paddleDistanceFromHeightWall
	mov bx, boardWidth
	sub bx, paddleDistanceFromWidthWall
	push ax
	push bx
	mov ax, boardHeight
	sub ax, paddleDistanceFromHeightWall
	sub ax, paddleHeight
	mov bx, boardWidth
	sub bx, paddleDistanceFromWidthWall
	sub bx, paddlewidth
	push ax
	push bx
	call drawRectangle
	mov [paddle2_x], bx
	mov [paddle2_y], ax

	; Draw ball
	push colorWhite
	mov cx, ballSize
	shr cx, 1 ; Cx holds the "Scope" of the ball so we can draw the ball equally in the center from the left and the right
	mov ax, boardHeight
	shr ax, 1
	add ax, cx
	mov bx, boardWidth
	shr bx, 1
	add bx, cx
	push ax
	push bx

	mov ax, boardHeight
	shr ax, 1
	sub ax, cx
	mov bx, boardWidth
	shr bx, 1
	sub bx, cx
	; Set the ball coordinates
	mov [ball_x], bx
	mov [ball_y], ax
	push ax
	push bx 
	call drawrectangle


	pop cx
	pop bx
	pop ax
	ret
endp drawBoard


x1 equ [bp+4]
y1 equ [bp+6]
x2 equ [bp+8]
y2 equ [bp+10]
color equ [bp+12]
proc drawRectangle
	; Function gets the edges of the paddle. The most left and high and most right and low
	; Params: x1, y1, x2, y2, color
	; Retrun: none
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	; x2 - x1 is the width of the paddle which is the times the outer loop will run
	; y2 - y1 is the height of the paddle which is the times the inner loop will run
	mov ax, x1 ; ax holds the current x value
	mov bx, y1 ; bx holds the current y value
	mov dx, x2 ; dx holds the width
	sub dx, x1
	cmp dx, 0
	je incX ; The reason for that is we treat a point ((0,0) for example) as the edge of the rectangle we want to draw but this point is actually a pixel
	            ; itself. When we want to draw a line the Y value or X value doesnt change and if we treat them as we treat other objects
				; the result of the subtruction will be 0 and then either the loop will not run or it will run 65K times.
	jmp drawWidth
incX:
	inc dx
drawWidth:
	mov bx, y1 ; After the drawHeight loop, bx has the value of the height of the paddle so we need to reset him
	mov cx, y2 ; cx holds the height
	sub cx, y
	cmp cx, 0
	je incY ; Same reason as explaind before
	jmp drawheight
incY:
	inc cx
	drawHeight:
		push color
		push bx
		push ax
		call drawpixel
		inc bx
		loop drawheight
	dec dx
	cmp dx, 0
	je enddrawRectangle
	inc ax
	jmp drawwidth
enddrawRectangle:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 10
endp drawRectangle

x equ [bp+4]
y equ [bp+6]
color equ [bp+8]
proc drawPixel
	; Params: x, y, color
	; Retrun: none
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov al, color
	mov ah, 0ch
	mov bh, 0
	mov cx, x
	mov dx, y
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 6
endp drawPixel

proc moveBall
	; This function moves the ball according to the values of the variables above
	; Params: None
	; Return: None
	push ax
	push bx
	; Move ball X axis
	push [ballSpeedX]
	mov ax, [ball_x]
	mov bx, [ball_y]
	add bx, ballSize
	add ax, ballSize
	push bx
	push ax
	push [ball_y]
	push [ball_x]
	call moveObjectX
	mov bx, [ballSpeedX]
	add [ball_x], bx
	; Move ball Y axis
	push [ballSpeedY]
	mov ax, [ball_x]
	mov bx, [ball_y]
	add bx, ballSize
	add ax, ballSize
	push bx
	push ax
	push [ball_y]
	push [ball_x]
	call moveObjectY
	mov bx, [ballSpeedY]
	add [ball_y], bx
	
	pop bx
	pop ax
	ret
endp moveball

proc handleUserInput
	; Function handles user input and moves the paddles according to it
	; Params: None
	; Returns: None
	push ax
	mov ah, 0
	int 16h
	; Comparing ah because arrows doesn't have ascii code, only scan codes
	; Arrows refer to paddle 2
	cmp ah, 48h
	je paddleNeg
	cmp ah, 50h
	je paddlePos
	cmp al, 'w'
	je paddleNeg
	cmp al, 's'
	je paddlePos
	jmp endhandleUserInput

; We have to change the sign of the speed according to the direction the user wants to move the paddle
paddleNeg:
	cmp [paddlespeed], 0
	jl endneg
	neg [paddlespeed]
endNeg:
	cmp ah, 48h
	je movepaddle2
	jmp movepaddle1

paddlePos:
	cmp [paddlespeed], 0
	jg endPos
	neg [paddlespeed]
endPos:
	cmp ah, 50h
	je movepaddle2
	jmp movepaddle1

movePaddle2:
	; Check if paddle isn't out of board
	mov ax, [paddle2_y]
	add ax, paddleHeight
	add ax, [paddlespeed]
	cmp ax, boardheight
	jg endhandleuserinput
	mov ax, [paddle2_y]
	add ax, [paddlespeed]
	cmp ax, 0
	jl endhandleuserinput

	push [paddlespeed]
	mov ax, [paddle2_y]
	add ax, paddleHeight
	push ax
	mov ax, [paddle2_x]
	add ax, paddlewidth
	push ax
	push [paddle2_y]
	push [paddle2_x]
	call moveobjecty
	mov ax, [paddlespeed]
	add [paddle2_y], ax
	jmp endhandleuserinput

movePaddle1:
	; Check if paddle isn't out of board
	mov ax, [paddle1_y]
	add ax, paddleHeight
	add ax, [paddlespeed]
	cmp ax, boardheight
	jg endhandleuserinput
	mov ax, [paddle1_y]
	add ax, [paddlespeed]
	cmp ax, 0
	jl endhandleuserinput

	push [paddlespeed]
	mov ax, [paddle1_y]
	add ax, paddleHeight
	push ax
	mov ax, [paddle1_x]
	add ax, paddlewidth
	push ax
	push [paddle1_y]
	push [paddle1_x]
	call moveobjecty
	mov ax, [paddlespeed]
	add [paddle1_y], ax
	
endhandleUserInput:
	pop ax
	ret
endp handleuserinput

proc collisionDetection
	; Function checks if the ball has collided with the paddles or the walls and plays hit sound. Updates the score. 
	; Params: None
	; Return: Ch will return 1 if a player has scored, 0 if not.
	;		Dl - Number of ticks to play wall hit sound
	;		Dh - number of ticks to play paddle hit sound
	; check collision with upper and down walls
	push ax
	push bx
	mov ax, [ball_y]
	; Check upper wall and lower wall
	cmp ax, 0
	je changeBallSpeedY
	add ax, ballSize
	cmp ax, boardheight
	je changeballspeedy

	mov ax, [ball_y]
	add ax, [ballspeedy]
	cmp ax, 0
	jl lowerBallSpeedUpperWall
	add ax, ballSize
	cmp ax, boardheight
	jg  lowerBallSpeedDownWall
	jmp checkpaddlecollision
	
changeBallSpeedY:
	mov bx, [savespeedy]
	mov [ballspeedy], bx
	neg [ballspeedy]
	call playwallsound
	mov dl, numOfSoundTicks
	jmp checkpaddlecollision
lowerBallSpeedUpperWall:
	; Saving the speed
	mov bx, [ballspeedy]
	mov [savespeedy], bx

	mov ax, [ball_y]
	neg ax
	mov [ballspeedy], ax
	jmp checkpaddlecollision
lowerBallSpeedDownWall:
	mov bx, [ballspeedy]
	mov [savespeedy], bx

	sub ax, [ballspeedy]
	mov bx, boardHeight
	sub bx, ax
	mov [ballspeedy], bx

checkPaddleCollision:
	; Paddle 1
	mov ax, paddleDistanceFromWidthWall
	add ax, paddleWidth
	cmp [ball_x], ax
	je checkpaddle1
	; Paddle 2
	mov ax, boardWidth
	sub ax, paddleDistanceFromWidthWall
	sub ax, paddleWidth
	mov bx, [ball_x]
	add bx, ballSize
	cmp bx, ax
	je checkPaddle2
	; Check if a player scored
	jmp checkScoring
checkPaddle1:
	mov ax, [ball_y]
	add ax, ballSize
	mov bx, [paddle1_y]
	cmp ax, bx
	jb checkScoring
	add bx, paddleHeight
	mov ax, [ball_y]
	cmp ax, bx
	ja checkScoring
	neg [ballspeedx]
	call playPaddleSound
	mov dh, numOfSoundTicks
	jmp endcollisiondetection
checkPaddle2:
	mov ax, [ball_y]
	add ax, ballSize
	mov bx, [paddle2_y]
	cmp ax, bx
	jb checkScoring
	add bx, paddleHeight
	mov ax, [ball_y]
	cmp ax, bx
	ja checkScoring
	neg [ballspeedx]
	call playPaddleSound
	mov dh, numOfSoundTicks
	jmp endcollisiondetection

checkScoring:
	mov ax, [ball_x]
	cmp ax, 0
	jle player1Scored
	add ax, ballSize
	cmp ax, boardwidth
	jge player2Scored
	mov ch, 0
	jmp endcollisiondetection
player1Scored:
	inc [player2]
	mov ch, 1
	jmp endcollisiondetection
player2Scored:
	inc [player1]
	mov ch, 1
endCollisionDetection:
	pop bx
	pop ax
	ret
endp collisionDetection

proc resetBoard
	; Fucntion resets the position of the ball and the variables related to it
	; Params: None
	; Return: None
	push ax

	; Erase the ball
	push colorblack
	mov ax, [ball_y]
	add ax, ballSize
	push ax
	mov ax, [ball_x]
	add ax, ballSize
	push ax
	push [ball_y]
	push [ball_x]
	call drawrectangle
	; Erase paddles
	push colorblack
	mov ax, [paddle1_y]
	add ax, paddleHeight
	push ax
	mov ax, [paddle1_x]
	add ax, paddleWidth
	push ax
	push [paddle1_y]
	push [paddle1_x]
	call drawrectangle
	
	push colorblack
	mov ax, [paddle2_y]
	add ax, paddleHeight
	push ax
	mov ax, [paddle2_x]
	add ax, paddleWidth
	push ax
	push [paddle2_y]
	push [paddle2_x]
	call drawrectangle

	; Draw new board and reset variables
	call drawboard
	
	; Reverse the speed of the ball
	neg [ballspeedx]
	neg [ballspeedy]

	pop ax
endp resetBoard

proc updateScore
	; Function that draws the score on the board
	; Params: None
	; Return: None
	push ax
	push bx
	push cx
	push dx
	; Draw left score
	mov ah, 2
	mov bh, 0
	mov dh, scoreBoardHeight
	shr dh, 3
	mov dl, scoreBoardWidth
	shr dl, 3
	int 10h
	mov ah, 9
	mov al, [player1]
	add al, '0'
	mov bh, 0
	mov bl, colorWhite
	mov cx, 1
	int 10h
	; Draw right score
	mov ah, 2
	mov bh, 0
	mov dh, scoreBoardHeight
	shr dh, 3

	mov dl, scoreBoardWidth
	shr dl, 3
	; If we did 1/8 of the screen in the right one we need 7/8 of the screen in the left one and thats a way to do it
	sub dl, scoreBoardWidth
	neg dl
	int 10h
	mov ah, 9
	mov al, [player2]
	add al, '0'
	mov bh, 0
	mov bl, colorWhite
	mov cx, 1
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp updatescore

proc restartGame
	; Function to ask the user if restart the game
	; Params: None
	; Return: ch = 1: restarg game, ch = 0: End game
	push ax
	push dx
	; Set text Mode
	mov ax, 2
	int 10h
	
	lea dx, [restartmsg]
	mov ah, 9
	int 21h
	
	mov ah, 0
	int 16h
	
	mov ch, 0
	cmp al, 'y'
	je restart
	cmp al, 'Y'
	je restart
	jmp endrestartgame
restart:
	mov ch, 1

endRestartGame:
	pop dx
	pop ax
	ret
endp restartgame

lastTimeRead equ [bp-2]
proc startGame
	; This function manages the game when its running
	; Params: None
	; Return: None
	push bp
	mov bp, sp
	sub sp, 2
	push ax
	mov ax, 40h
	mov es, ax
	mov ax, [clock]
	mov lastTimeRead, ax
firstTick:
	cmp ax, [clock]
	je firsttick
gameRun:
	mov ax, [clock]
	cmp ax, lastTimeRead
	je checkuserinput
	; The ball will only move if the ax register has changed which holds the hundredths of a second and changes only
	; every 55 milliseconds which means this function will be called every approximately 18 times a second
	call moveball
	call collisionDetection
	; Check win
	cmp [player1], scoretowin
	je endgame
	cmp [player2], scoretowin
	je endgame
	call updatescore
checkSound:
	cmp dl, 0 ; Dl stores the number of ticks left to play
	dec dl
	jne checkPaddleSound
	call stopsound
	
checkPaddleSound:
	cmp dh, 0
	dec dh
	jne checkwin
	call stopsound


checkWin:
	mov lastTimeRead, ax
	cmp ch, 1
	jne checkuserinput
	call resetBoard
	jmp firsttick
checkUserInput:
	mov ah, 1
	int 16h
	jz gameRun
	call handleUserInput
	jmp gamerun
endGame:
	pop ax
	add sp, 2
	pop bp
	ret
endp startgame

proc Game
	; This function manages all the stages in the game
	; Params: None
	; Return: None
	push ax

startRun:	
	; Set video mode
	mov ax, 13h
	int 10h
	; Restart Score
	mov [player1], 0
	mov [player2], 0
	call drawboard
	call startgame
	call restartGame
	cmp ch, 1
	je startrun
	pop ax
	ret
endp Game

start:
	mov ax, @data
	mov ds, ax

	call Game
	
exit:
	mov ax, 4c00h
	int 21h
END start


