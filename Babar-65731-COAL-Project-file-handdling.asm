 org 100h
.DATA
    ; Messages and prompts
    msg_welcome DB 'Simple File Handling System', 13, 10, '$'
    msg_menu DB 13, 10, 'Choose operation:', 13, 10
             DB '1. Create and Write to File', 13, 10
             DB '2. Read from File', 13, 10
             DB '3. Append to File', 13, 10
             DB '4. Exit', 13, 10
             DB 'Enter choice (1-4): $'
    
    msg_filename DB 13, 10, 'Enter filename (max 8 chars): $'
    msg_content DB 13, 10, 'Enter content: $'
    msg_success DB 13, 10, 'Operation successful!$'
    msg_error DB 13, 10, 'Error occurred!$'
    msg_file_content DB 13, 10, 'File content: $'
    msg_not_found DB 13, 10, 'File not found!$'
    msg_newline DB 13, 10, '$'
    msg_created DB 13, 10, 'File created successfully!$'
    
    ; File handling variables
    filename DB 9 DUP(?)     ; 8 chars + null terminator
    buffer DB 100 DUP('$')   ; Buffer for file content
    file_handle DW ?
    
    ; Constants
    CR EQU 13
    LF EQU 10

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX          ; Set ES to data segment for string operations
    
start:
    ; Display welcome message
    MOV AH, 09H
    LEA DX, msg_welcome
    INT 21H
    
menu:
    ; Display menu
    MOV AH, 09H
    LEA DX, msg_menu
    INT 21H
    
    ; Get user choice
    MOV AH, 01H
    INT 21H
    
    ; Process choice
    CMP AL, '1'
    JE create_write_file
    CMP AL, '2'
    JE read_file
    CMP AL, '3'
    JE append_file
    CMP AL, '4'
    JE exit_program
    
    ; Invalid choice - show menu again
    JMP menu

create_write_file:
    CALL get_filename
    CALL create_file
    JC operation_error   ; If carry flag set, error occurred
    
    CALL get_content
    CALL write_file
    JC operation_error
    
    CALL close_file
    MOV AH, 09H
    LEA DX, msg_created
    INT 21H
    JMP start

read_file:
    CALL get_filename
    CALL open_file
    JC file_not_found
    
    CALL read_file_content
    JC operation_error
    
    CALL display_file_content
    CALL close_file
    JMP start

append_file:
    CALL get_filename
    CALL open_file_append
    JC operation_error
    
    CALL get_content
    CALL write_file
    JC operation_error
    
    CALL close_file
    MOV AH, 09H
    LEA DX, msg_success
    INT 21H
    JMP start

file_not_found:
    MOV AH, 09H
    LEA DX, msg_not_found
    INT 21H
    JMP start

operation_error:
    MOV AH, 09H
    LEA DX, msg_error
    INT 21H
    JMP start

exit_program:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; Procedure to get filename from user
get_filename PROC
    MOV AH, 09H
    LEA DX, msg_filename
    INT 21H
    
    ; Clear filename buffer
    MOV CX, 9
    LEA DI, filename
    MOV AL, 0
    REP STOSB
    
    ; Read filename
    LEA DI, filename
    MOV CX, 8          ; Max 8 characters
    
read_filename:
    MOV AH, 01H
    INT 21H
    
    CMP AL, CR         ; Check for Enter key
    JE filename_done
    CMP AL, 0DH        ; Alternative check
    JE filename_done
    
    MOV [DI], AL       ; Store character
    INC DI
    LOOP read_filename
    
filename_done:
    MOV BYTE PTR [DI], 0  ; Null terminate
    RET
get_filename ENDP

; Procedure to get content from user
get_content PROC
    MOV AH, 09H
    LEA DX, msg_content
    INT 21H
    
    ; Clear buffer
    MOV CX, 100
    LEA DI, buffer
    MOV AL, '$'
    REP STOSB
    
    ; Read content
    LEA DI, buffer
    MOV CX, 99         ; Max 99 characters
    
read_content:
    MOV AH, 01H
    INT 21H
    
    CMP AL, CR         ; Check for Enter key
    JE content_done
    CMP AL, 0DH        ; Alternative check
    JE content_done
    
    MOV [DI], AL       ; Store character
    INC DI
    LOOP read_content
    
content_done:
    MOV BYTE PTR [DI], '$'  ; String terminator for display
    RET
get_content ENDP

; Procedure to create a new file
create_file PROC
    LEA DX, filename
    MOV CX, 0          ; Normal file attributes
    MOV AH, 3CH        ; DOS create file function
    INT 21H
    MOV file_handle, AX ; Save file handle
    RET
create_file ENDP

; Procedure to open existing file
open_file PROC
    LEA DX, filename
    MOV AL, 0          ; Read-only mode
    MOV AH, 3DH        ; DOS open file function
    INT 21H
    MOV file_handle, AX ; Save file handle
    RET
open_file ENDP

; Procedure to open file for appending
open_file_append PROC
    LEA DX, filename
    MOV AL, 2          ; Read/write mode
    MOV AH, 3DH        ; DOS open file function
    INT 21H
    MOV file_handle, AX ; Save file handle
    
    ; Move file pointer to end
    MOV BX, file_handle
    MOV AL, 2          ; Seek from end
    MOV CX, 0
    MOV DX, 0
    MOV AH, 42H        ; DOS seek function
    INT 21H
    RET
open_file_append ENDP

; Procedure to write to file
write_file PROC
    MOV BX, file_handle
    
    ; Calculate string length
    LEA SI, buffer
    MOV CX, 0
    
count_chars:
    CMP BYTE PTR [SI], '$'
    JE done_counting
    INC SI
    INC CX
    JMP count_chars
    
done_counting:
    LEA DX, buffer
    MOV AH, 40H        ; DOS write to file function
    INT 21H
    RET
write_file ENDP

; Procedure to read from file
read_file_content PROC
    ; Clear buffer first
    MOV CX, 100
    LEA DI, buffer
    MOV AL, '$'
    REP STOSB
    
    MOV BX, file_handle
    LEA DX, buffer
    MOV CX, 99         ; Max bytes to read
    MOV AH, 3FH        ; DOS read from file function
    INT 21H
    
    ; Null terminate the read data
    LEA SI, buffer
    ADD SI, AX
    MOV BYTE PTR [SI], '$'
    RET
read_file_content ENDP

; Procedure to display file content
display_file_content PROC
    MOV AH, 09H
    LEA DX, msg_file_content
    INT 21H
    
    LEA DX, buffer
    INT 21H
    
    MOV AH, 09H
    LEA DX, msg_newline
    INT 21H
    RET
display_file_content ENDP

; Procedure to close file
close_file PROC
    MOV BX, file_handle
    MOV AH, 3EH        ; DOS close file function
    INT 21H
    RET
close_file ENDP

END MAIN