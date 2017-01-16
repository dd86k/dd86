/*
 * Interpreter.cpp: Legacy machine code interpreter.
 */

/* 
 * From the Intel 80386 manual (Page 412):
 The opcode tables that follow aid in interpreting 80386 object code. Use
 the high-order four bits of the opcode as an index to a row of the opcode
 table; use the low-order four bits as an index to a column of the table. If
 the opcode is 0FH, refer to the two-byte opcode table and use the second
 byte of the opcode to index the rows and columns of that table.
 */

enum Op {

};

// Should be returning something for error checking.
void Start(wchar_t *filename) {

}