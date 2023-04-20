.DEVICE ATmega328p ;define correct device

    ldi r16, $f8 ; f - pins 4-7, 8 - pin 3
    out ddrd, r16 ; config pins 3-7 of portd to be output
    ldi r16, 0
    out ddrb, r16
  

    ldi r17, $09 ; load password into sram
    sts 0x0100, r17 ; store password value into loacation in sram to be compared with later

    ldi r18, $00 ; register for keeping track of pw input - 1s/0s
    ldi r20, $00 ; register for output pattern to progress lights

mainloop:
    cpi r20, $0f ; if all bits are set in lower half of r20, 4 buttons have been pressed
    BREQ checkPW ; if so, check if correct pw has been entered


    in r16, pinb ; read in from buttons
    andi r16, $03 ; check 1
    cpi r16, $01 ; if comparison matches, 
    BREQ button1pressed

    ; check if button 2 pressed
    cpi r16, $02
    BREQ button2pressed

  
rjmp mainloop ; repeat mainloop



button1pressed:

    in r16, pinb ; read in from portb buttons 
    andi r16, $03 ; 
    cpi r16, $01 ; if result of andi operation is $01, then repeat button2presssed loop while button is held down
    BREQ button1pressed ; repeat loop while button is held

    
    cpi r16, $00 ; if r16 is not equal to $01, the second button has also been pressed simultaneously or the first button has been released
    BREQ updateLeft ; check if button has been released, if so we update left and add a 0 to pw input

    ; check if both buttons are now pressed
    cpi r16, $03
    BREQ bothpressed ; go to reset loop if so

button2pressed: ; use similar code to button1pressed

    in r16, pinb ; read in 
    andi r16, $03 
    cpi r16, $02 ; if result of andi operation is $02, then repeat button2presssed loop while button is held down
    BREQ button2pressed ; returns to beginning of loop

    cpi r16, $00 ; if r16 is not equal to $02, the first button has also been pressed simultaneously or the second button has been released
    BREQ updateRight 

    cpi r16, $03 ; if 16 holds $03 both buttons are being pressed, meaning user wants to reset progress
    BREQ bothpressed
  
bothpressed:
    in r16, pinb ; read in
    andi r16, $03 ;  andi with r16
    cpi r16, $03 ; check for both buttons being pressed
    ;cpi r16, $00
   ; BRNE reset 
    BREQ bothpressed ; repeat this loop while one or more buttons held down
   

    jmp reset ; otherwise reset progress
   

updateLeft: ; button 1 pressed
    

    lsl r18 ; left button = 0
    
    lsl r20 ; multiply progress light counter by 2
    subi r20,  -1 ; add next bit  
    swap r20  ; swap nibbles so counter pattern maps to corret pins for output
    out portd, r20 ; light up progress LED(s)
    swap r20 ; switch nibbles back for next time
    
    jmp mainloop

updateRight: ; button 2 pressed
    lsl r18
    subi r18,  -1 ; right button = 1, add a 1 

    lsl r20 ; multiply counter by 2
    subi r20,  -1 ; add +1 
    swap r20
    out portd, r20 ; light up progress LED
    swap r20

    jmp mainloop

resetloop: ; loop to sit in after all inputs have been given until user chooses to reset 
    in r16, pinb ; read in from buttons

    andi r16, $03 ; check if any combination is pressed
    cpi r16, $03 
    BREQ resetloop ; repeat loop if so
    cpi r16, $02
    BREQ resetloop
    cpi r16, $01
    BREQ resetloop
    rjmp reset ; if nothing is being pressed we can reset


reset: ; both buttons pressed down
    clr r20 ; clear progress LEDs
    clr r18 ; clear pw register
    jmp mainloop

checkPW:

    lds r19, 0x0100 ; load pw from sram for comparison
    cp r18, r19 ; compare input with actual pw
    BREQ unlock ; 

    rjmp resetloop

unlock: ; light up last LED
    sbi portd, 3 ; set bit to light up "unlocked" LED
    rjmp resetloop ; jump to loop that waits for user to reset lock

