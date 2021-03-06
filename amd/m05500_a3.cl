/**
 * Author......: Jens Steube <jens.steube@gmail.com>
 * License.....: MIT
 */

#define _MD4_
#define _SCALAR_

#include "include/constants.h"
#include "include/kernel_vendor.h"

#ifdef  VLIW1
#define VECT_SIZE1
#endif

#ifdef  VLIW4
#define VECT_SIZE4
#endif

#ifdef  VLIW5
#define VECT_SIZE4
#endif

#define DGST_R0 0
#define DGST_R1 1
#define DGST_R2 2
#define DGST_R3 3

#include "include/kernel_functions.c"
#include "types_amd.c"
#include "common_amd.c"

#ifdef  VECT_SIZE1
#define VECT_COMPARE_S "check_single_vect1_comp4_warp.c"
#define VECT_COMPARE_M "check_multi_vect1_comp4_warp.c"
#endif

#ifdef  VECT_SIZE2
#define VECT_COMPARE_S "check_single_vect2_comp4_warp.c"
#define VECT_COMPARE_M "check_multi_vect2_comp4_warp.c"
#endif

#ifdef  VECT_SIZE4
#define VECT_COMPARE_S "check_single_vect4_comp4_warp.c"
#define VECT_COMPARE_M "check_multi_vect4_comp4_warp.c"
#endif

#define PERM_OP(a,b,tt,n,m) \
{                           \
  tt = a >> n;              \
  tt = tt ^ b;              \
  tt = tt & m;              \
  b = b ^ tt;               \
  tt = tt << n;             \
  a = a ^ tt;               \
}

#define HPERM_OP(a,tt,n,m)  \
{                           \
  tt = a << (16 + n);       \
  tt = tt ^ a;              \
  tt = tt & m;              \
  a  = a ^ tt;              \
  tt = tt >> (16 + n);      \
  a  = a ^ tt;              \
}

__constant u32 c_SPtrans[8][64] =
{
  /* nibble 0 */
  0x02080800, 0x00080000, 0x02000002, 0x02080802,
  0x02000000, 0x00080802, 0x00080002, 0x02000002,
  0x00080802, 0x02080800, 0x02080000, 0x00000802,
  0x02000802, 0x02000000, 0x00000000, 0x00080002,
  0x00080000, 0x00000002, 0x02000800, 0x00080800,
  0x02080802, 0x02080000, 0x00000802, 0x02000800,
  0x00000002, 0x00000800, 0x00080800, 0x02080002,
  0x00000800, 0x02000802, 0x02080002, 0x00000000,
  0x00000000, 0x02080802, 0x02000800, 0x00080002,
  0x02080800, 0x00080000, 0x00000802, 0x02000800,
  0x02080002, 0x00000800, 0x00080800, 0x02000002,
  0x00080802, 0x00000002, 0x02000002, 0x02080000,
  0x02080802, 0x00080800, 0x02080000, 0x02000802,
  0x02000000, 0x00000802, 0x00080002, 0x00000000,
  0x00080000, 0x02000000, 0x02000802, 0x02080800,
  0x00000002, 0x02080002, 0x00000800, 0x00080802,
  /* nibble 1 */
  0x40108010, 0x00000000, 0x00108000, 0x40100000,
  0x40000010, 0x00008010, 0x40008000, 0x00108000,
  0x00008000, 0x40100010, 0x00000010, 0x40008000,
  0x00100010, 0x40108000, 0x40100000, 0x00000010,
  0x00100000, 0x40008010, 0x40100010, 0x00008000,
  0x00108010, 0x40000000, 0x00000000, 0x00100010,
  0x40008010, 0x00108010, 0x40108000, 0x40000010,
  0x40000000, 0x00100000, 0x00008010, 0x40108010,
  0x00100010, 0x40108000, 0x40008000, 0x00108010,
  0x40108010, 0x00100010, 0x40000010, 0x00000000,
  0x40000000, 0x00008010, 0x00100000, 0x40100010,
  0x00008000, 0x40000000, 0x00108010, 0x40008010,
  0x40108000, 0x00008000, 0x00000000, 0x40000010,
  0x00000010, 0x40108010, 0x00108000, 0x40100000,
  0x40100010, 0x00100000, 0x00008010, 0x40008000,
  0x40008010, 0x00000010, 0x40100000, 0x00108000,
  /* nibble 2 */
  0x04000001, 0x04040100, 0x00000100, 0x04000101,
  0x00040001, 0x04000000, 0x04000101, 0x00040100,
  0x04000100, 0x00040000, 0x04040000, 0x00000001,
  0x04040101, 0x00000101, 0x00000001, 0x04040001,
  0x00000000, 0x00040001, 0x04040100, 0x00000100,
  0x00000101, 0x04040101, 0x00040000, 0x04000001,
  0x04040001, 0x04000100, 0x00040101, 0x04040000,
  0x00040100, 0x00000000, 0x04000000, 0x00040101,
  0x04040100, 0x00000100, 0x00000001, 0x00040000,
  0x00000101, 0x00040001, 0x04040000, 0x04000101,
  0x00000000, 0x04040100, 0x00040100, 0x04040001,
  0x00040001, 0x04000000, 0x04040101, 0x00000001,
  0x00040101, 0x04000001, 0x04000000, 0x04040101,
  0x00040000, 0x04000100, 0x04000101, 0x00040100,
  0x04000100, 0x00000000, 0x04040001, 0x00000101,
  0x04000001, 0x00040101, 0x00000100, 0x04040000,
  /* nibble 3 */
  0x00401008, 0x10001000, 0x00000008, 0x10401008,
  0x00000000, 0x10400000, 0x10001008, 0x00400008,
  0x10401000, 0x10000008, 0x10000000, 0x00001008,
  0x10000008, 0x00401008, 0x00400000, 0x10000000,
  0x10400008, 0x00401000, 0x00001000, 0x00000008,
  0x00401000, 0x10001008, 0x10400000, 0x00001000,
  0x00001008, 0x00000000, 0x00400008, 0x10401000,
  0x10001000, 0x10400008, 0x10401008, 0x00400000,
  0x10400008, 0x00001008, 0x00400000, 0x10000008,
  0x00401000, 0x10001000, 0x00000008, 0x10400000,
  0x10001008, 0x00000000, 0x00001000, 0x00400008,
  0x00000000, 0x10400008, 0x10401000, 0x00001000,
  0x10000000, 0x10401008, 0x00401008, 0x00400000,
  0x10401008, 0x00000008, 0x10001000, 0x00401008,
  0x00400008, 0x00401000, 0x10400000, 0x10001008,
  0x00001008, 0x10000000, 0x10000008, 0x10401000,
  /* nibble 4 */
  0x08000000, 0x00010000, 0x00000400, 0x08010420,
  0x08010020, 0x08000400, 0x00010420, 0x08010000,
  0x00010000, 0x00000020, 0x08000020, 0x00010400,
  0x08000420, 0x08010020, 0x08010400, 0x00000000,
  0x00010400, 0x08000000, 0x00010020, 0x00000420,
  0x08000400, 0x00010420, 0x00000000, 0x08000020,
  0x00000020, 0x08000420, 0x08010420, 0x00010020,
  0x08010000, 0x00000400, 0x00000420, 0x08010400,
  0x08010400, 0x08000420, 0x00010020, 0x08010000,
  0x00010000, 0x00000020, 0x08000020, 0x08000400,
  0x08000000, 0x00010400, 0x08010420, 0x00000000,
  0x00010420, 0x08000000, 0x00000400, 0x00010020,
  0x08000420, 0x00000400, 0x00000000, 0x08010420,
  0x08010020, 0x08010400, 0x00000420, 0x00010000,
  0x00010400, 0x08010020, 0x08000400, 0x00000420,
  0x00000020, 0x00010420, 0x08010000, 0x08000020,
  /* nibble 5 */
  0x80000040, 0x00200040, 0x00000000, 0x80202000,
  0x00200040, 0x00002000, 0x80002040, 0x00200000,
  0x00002040, 0x80202040, 0x00202000, 0x80000000,
  0x80002000, 0x80000040, 0x80200000, 0x00202040,
  0x00200000, 0x80002040, 0x80200040, 0x00000000,
  0x00002000, 0x00000040, 0x80202000, 0x80200040,
  0x80202040, 0x80200000, 0x80000000, 0x00002040,
  0x00000040, 0x00202000, 0x00202040, 0x80002000,
  0x00002040, 0x80000000, 0x80002000, 0x00202040,
  0x80202000, 0x00200040, 0x00000000, 0x80002000,
  0x80000000, 0x00002000, 0x80200040, 0x00200000,
  0x00200040, 0x80202040, 0x00202000, 0x00000040,
  0x80202040, 0x00202000, 0x00200000, 0x80002040,
  0x80000040, 0x80200000, 0x00202040, 0x00000000,
  0x00002000, 0x80000040, 0x80002040, 0x80202000,
  0x80200000, 0x00002040, 0x00000040, 0x80200040,
  /* nibble 6 */
  0x00004000, 0x00000200, 0x01000200, 0x01000004,
  0x01004204, 0x00004004, 0x00004200, 0x00000000,
  0x01000000, 0x01000204, 0x00000204, 0x01004000,
  0x00000004, 0x01004200, 0x01004000, 0x00000204,
  0x01000204, 0x00004000, 0x00004004, 0x01004204,
  0x00000000, 0x01000200, 0x01000004, 0x00004200,
  0x01004004, 0x00004204, 0x01004200, 0x00000004,
  0x00004204, 0x01004004, 0x00000200, 0x01000000,
  0x00004204, 0x01004000, 0x01004004, 0x00000204,
  0x00004000, 0x00000200, 0x01000000, 0x01004004,
  0x01000204, 0x00004204, 0x00004200, 0x00000000,
  0x00000200, 0x01000004, 0x00000004, 0x01000200,
  0x00000000, 0x01000204, 0x01000200, 0x00004200,
  0x00000204, 0x00004000, 0x01004204, 0x01000000,
  0x01004200, 0x00000004, 0x00004004, 0x01004204,
  0x01000004, 0x01004200, 0x01004000, 0x00004004,
  /* nibble 7 */
  0x20800080, 0x20820000, 0x00020080, 0x00000000,
  0x20020000, 0x00800080, 0x20800000, 0x20820080,
  0x00000080, 0x20000000, 0x00820000, 0x00020080,
  0x00820080, 0x20020080, 0x20000080, 0x20800000,
  0x00020000, 0x00820080, 0x00800080, 0x20020000,
  0x20820080, 0x20000080, 0x00000000, 0x00820000,
  0x20000000, 0x00800000, 0x20020080, 0x20800080,
  0x00800000, 0x00020000, 0x20820000, 0x00000080,
  0x00800000, 0x00020000, 0x20000080, 0x20820080,
  0x00020080, 0x20000000, 0x00000000, 0x00820000,
  0x20800080, 0x20020080, 0x20020000, 0x00800080,
  0x20820000, 0x00000080, 0x00800080, 0x20020000,
  0x20820080, 0x00800000, 0x20800000, 0x20000080,
  0x00820000, 0x00020080, 0x20020080, 0x20800000,
  0x00000080, 0x20820000, 0x00820080, 0x00000000,
  0x20000000, 0x20800080, 0x00020000, 0x00820080,
};

__constant u32 c_skb[8][64] =
{
  /* for C bits (numbered as per FIPS 46) 1 2 3 4 5 6 */
  0x00000000, 0x00000010, 0x20000000, 0x20000010,
  0x00010000, 0x00010010, 0x20010000, 0x20010010,
  0x00000800, 0x00000810, 0x20000800, 0x20000810,
  0x00010800, 0x00010810, 0x20010800, 0x20010810,
  0x00000020, 0x00000030, 0x20000020, 0x20000030,
  0x00010020, 0x00010030, 0x20010020, 0x20010030,
  0x00000820, 0x00000830, 0x20000820, 0x20000830,
  0x00010820, 0x00010830, 0x20010820, 0x20010830,
  0x00080000, 0x00080010, 0x20080000, 0x20080010,
  0x00090000, 0x00090010, 0x20090000, 0x20090010,
  0x00080800, 0x00080810, 0x20080800, 0x20080810,
  0x00090800, 0x00090810, 0x20090800, 0x20090810,
  0x00080020, 0x00080030, 0x20080020, 0x20080030,
  0x00090020, 0x00090030, 0x20090020, 0x20090030,
  0x00080820, 0x00080830, 0x20080820, 0x20080830,
  0x00090820, 0x00090830, 0x20090820, 0x20090830,
  /* for C bits (numbered as per FIPS 46) 7 8 10 11 12 13 */
  0x00000000, 0x02000000, 0x00002000, 0x02002000,
  0x00200000, 0x02200000, 0x00202000, 0x02202000,
  0x00000004, 0x02000004, 0x00002004, 0x02002004,
  0x00200004, 0x02200004, 0x00202004, 0x02202004,
  0x00000400, 0x02000400, 0x00002400, 0x02002400,
  0x00200400, 0x02200400, 0x00202400, 0x02202400,
  0x00000404, 0x02000404, 0x00002404, 0x02002404,
  0x00200404, 0x02200404, 0x00202404, 0x02202404,
  0x10000000, 0x12000000, 0x10002000, 0x12002000,
  0x10200000, 0x12200000, 0x10202000, 0x12202000,
  0x10000004, 0x12000004, 0x10002004, 0x12002004,
  0x10200004, 0x12200004, 0x10202004, 0x12202004,
  0x10000400, 0x12000400, 0x10002400, 0x12002400,
  0x10200400, 0x12200400, 0x10202400, 0x12202400,
  0x10000404, 0x12000404, 0x10002404, 0x12002404,
  0x10200404, 0x12200404, 0x10202404, 0x12202404,
  /* for C bits (numbered as per FIPS 46) 14 15 16 17 19 20 */
  0x00000000, 0x00000001, 0x00040000, 0x00040001,
  0x01000000, 0x01000001, 0x01040000, 0x01040001,
  0x00000002, 0x00000003, 0x00040002, 0x00040003,
  0x01000002, 0x01000003, 0x01040002, 0x01040003,
  0x00000200, 0x00000201, 0x00040200, 0x00040201,
  0x01000200, 0x01000201, 0x01040200, 0x01040201,
  0x00000202, 0x00000203, 0x00040202, 0x00040203,
  0x01000202, 0x01000203, 0x01040202, 0x01040203,
  0x08000000, 0x08000001, 0x08040000, 0x08040001,
  0x09000000, 0x09000001, 0x09040000, 0x09040001,
  0x08000002, 0x08000003, 0x08040002, 0x08040003,
  0x09000002, 0x09000003, 0x09040002, 0x09040003,
  0x08000200, 0x08000201, 0x08040200, 0x08040201,
  0x09000200, 0x09000201, 0x09040200, 0x09040201,
  0x08000202, 0x08000203, 0x08040202, 0x08040203,
  0x09000202, 0x09000203, 0x09040202, 0x09040203,
  /* for C bits (numbered as per FIPS 46) 21 23 24 26 27 28 */
  0x00000000, 0x00100000, 0x00000100, 0x00100100,
  0x00000008, 0x00100008, 0x00000108, 0x00100108,
  0x00001000, 0x00101000, 0x00001100, 0x00101100,
  0x00001008, 0x00101008, 0x00001108, 0x00101108,
  0x04000000, 0x04100000, 0x04000100, 0x04100100,
  0x04000008, 0x04100008, 0x04000108, 0x04100108,
  0x04001000, 0x04101000, 0x04001100, 0x04101100,
  0x04001008, 0x04101008, 0x04001108, 0x04101108,
  0x00020000, 0x00120000, 0x00020100, 0x00120100,
  0x00020008, 0x00120008, 0x00020108, 0x00120108,
  0x00021000, 0x00121000, 0x00021100, 0x00121100,
  0x00021008, 0x00121008, 0x00021108, 0x00121108,
  0x04020000, 0x04120000, 0x04020100, 0x04120100,
  0x04020008, 0x04120008, 0x04020108, 0x04120108,
  0x04021000, 0x04121000, 0x04021100, 0x04121100,
  0x04021008, 0x04121008, 0x04021108, 0x04121108,
  /* for D bits (numbered as per FIPS 46) 1 2 3 4 5 6 */
  0x00000000, 0x10000000, 0x00010000, 0x10010000,
  0x00000004, 0x10000004, 0x00010004, 0x10010004,
  0x20000000, 0x30000000, 0x20010000, 0x30010000,
  0x20000004, 0x30000004, 0x20010004, 0x30010004,
  0x00100000, 0x10100000, 0x00110000, 0x10110000,
  0x00100004, 0x10100004, 0x00110004, 0x10110004,
  0x20100000, 0x30100000, 0x20110000, 0x30110000,
  0x20100004, 0x30100004, 0x20110004, 0x30110004,
  0x00001000, 0x10001000, 0x00011000, 0x10011000,
  0x00001004, 0x10001004, 0x00011004, 0x10011004,
  0x20001000, 0x30001000, 0x20011000, 0x30011000,
  0x20001004, 0x30001004, 0x20011004, 0x30011004,
  0x00101000, 0x10101000, 0x00111000, 0x10111000,
  0x00101004, 0x10101004, 0x00111004, 0x10111004,
  0x20101000, 0x30101000, 0x20111000, 0x30111000,
  0x20101004, 0x30101004, 0x20111004, 0x30111004,
  /* for D bits (numbered as per FIPS 46) 8 9 11 12 13 14 */
  0x00000000, 0x08000000, 0x00000008, 0x08000008,
  0x00000400, 0x08000400, 0x00000408, 0x08000408,
  0x00020000, 0x08020000, 0x00020008, 0x08020008,
  0x00020400, 0x08020400, 0x00020408, 0x08020408,
  0x00000001, 0x08000001, 0x00000009, 0x08000009,
  0x00000401, 0x08000401, 0x00000409, 0x08000409,
  0x00020001, 0x08020001, 0x00020009, 0x08020009,
  0x00020401, 0x08020401, 0x00020409, 0x08020409,
  0x02000000, 0x0A000000, 0x02000008, 0x0A000008,
  0x02000400, 0x0A000400, 0x02000408, 0x0A000408,
  0x02020000, 0x0A020000, 0x02020008, 0x0A020008,
  0x02020400, 0x0A020400, 0x02020408, 0x0A020408,
  0x02000001, 0x0A000001, 0x02000009, 0x0A000009,
  0x02000401, 0x0A000401, 0x02000409, 0x0A000409,
  0x02020001, 0x0A020001, 0x02020009, 0x0A020009,
  0x02020401, 0x0A020401, 0x02020409, 0x0A020409,
  /* for D bits (numbered as per FIPS 46) 16 17 18 19 20 21 */
  0x00000000, 0x00000100, 0x00080000, 0x00080100,
  0x01000000, 0x01000100, 0x01080000, 0x01080100,
  0x00000010, 0x00000110, 0x00080010, 0x00080110,
  0x01000010, 0x01000110, 0x01080010, 0x01080110,
  0x00200000, 0x00200100, 0x00280000, 0x00280100,
  0x01200000, 0x01200100, 0x01280000, 0x01280100,
  0x00200010, 0x00200110, 0x00280010, 0x00280110,
  0x01200010, 0x01200110, 0x01280010, 0x01280110,
  0x00000200, 0x00000300, 0x00080200, 0x00080300,
  0x01000200, 0x01000300, 0x01080200, 0x01080300,
  0x00000210, 0x00000310, 0x00080210, 0x00080310,
  0x01000210, 0x01000310, 0x01080210, 0x01080310,
  0x00200200, 0x00200300, 0x00280200, 0x00280300,
  0x01200200, 0x01200300, 0x01280200, 0x01280300,
  0x00200210, 0x00200310, 0x00280210, 0x00280310,
  0x01200210, 0x01200310, 0x01280210, 0x01280310,
  /* for D bits (numbered as per FIPS 46) 22 23 24 25 27 28 */
  0x00000000, 0x04000000, 0x00040000, 0x04040000,
  0x00000002, 0x04000002, 0x00040002, 0x04040002,
  0x00002000, 0x04002000, 0x00042000, 0x04042000,
  0x00002002, 0x04002002, 0x00042002, 0x04042002,
  0x00000020, 0x04000020, 0x00040020, 0x04040020,
  0x00000022, 0x04000022, 0x00040022, 0x04040022,
  0x00002020, 0x04002020, 0x00042020, 0x04042020,
  0x00002022, 0x04002022, 0x00042022, 0x04042022,
  0x00000800, 0x04000800, 0x00040800, 0x04040800,
  0x00000802, 0x04000802, 0x00040802, 0x04040802,
  0x00002800, 0x04002800, 0x00042800, 0x04042800,
  0x00002802, 0x04002802, 0x00042802, 0x04042802,
  0x00000820, 0x04000820, 0x00040820, 0x04040820,
  0x00000822, 0x04000822, 0x00040822, 0x04040822,
  0x00002820, 0x04002820, 0x00042820, 0x04042820,
  0x00002822, 0x04002822, 0x00042822, 0x04042822
};

__constant u32 shifts3s0[16] = {  1,  1,  2,  2,  2,  2,  2,  2,  1,  2,  2,  2,  2,  2,  2,  1 };
__constant u32 shifts3s1[16] = { 27, 27, 26, 26, 26, 26, 26, 26, 27, 26, 26, 26, 26, 26, 26, 27 };

#ifdef VECT_SIZE1
#define BOX(i,n,S) (u32x) ((S)[(n)][(i)])
#endif

#ifdef VECT_SIZE2
#define BOX(i,n,S) (u32x) ((S)[(n)][(i).s0], (S)[(n)][(i).s1])
#endif

#ifdef VECT_SIZE4
#define BOX(i,n,S) (u32x) ((S)[(n)][(i).s0], (S)[(n)][(i).s1], (S)[(n)][(i).s2], (S)[(n)][(i).s3])
#endif

static void _des_crypt_encrypt (u32x iv[2], u32x data[2], u32x Kc[16], u32x Kd[16], __local u32 s_SPtrans[8][64])
{
  u32x r = data[0];
  u32x l = data[1];

  #pragma unroll 16
  for (u32 i = 0; i < 16; i += 2)
  {
    u32x u;
    u32x t;

    u = Kc[i + 0] ^ rotl32 (r, 30u);
    t = Kd[i + 0] ^ rotl32 (r, 26u);

    l = l
      ^ BOX (amd_bfe (u,  0, 6), 0, s_SPtrans)
      ^ BOX (amd_bfe (u,  8, 6), 2, s_SPtrans)
      ^ BOX (amd_bfe (u, 16, 6), 4, s_SPtrans)
      ^ BOX (amd_bfe (u, 24, 6), 6, s_SPtrans)
      ^ BOX (amd_bfe (t,  0, 6), 1, s_SPtrans)
      ^ BOX (amd_bfe (t,  8, 6), 3, s_SPtrans)
      ^ BOX (amd_bfe (t, 16, 6), 5, s_SPtrans)
      ^ BOX (amd_bfe (t, 24, 6), 7, s_SPtrans);

    u = Kc[i + 1] ^ rotl32 (l, 30u);
    t = Kd[i + 1] ^ rotl32 (l, 26u);

    r = r
      ^ BOX (amd_bfe (u,  0, 6), 0, s_SPtrans)
      ^ BOX (amd_bfe (u,  8, 6), 2, s_SPtrans)
      ^ BOX (amd_bfe (u, 16, 6), 4, s_SPtrans)
      ^ BOX (amd_bfe (u, 24, 6), 6, s_SPtrans)
      ^ BOX (amd_bfe (t,  0, 6), 1, s_SPtrans)
      ^ BOX (amd_bfe (t,  8, 6), 3, s_SPtrans)
      ^ BOX (amd_bfe (t, 16, 6), 5, s_SPtrans)
      ^ BOX (amd_bfe (t, 24, 6), 7, s_SPtrans);
  }

  iv[0] = l;
  iv[1] = r;
}

static void _des_crypt_keysetup (u32x c, u32x d, u32x Kc[16], u32x Kd[16], __local u32 s_skb[8][64])
{
  u32x tt;

  PERM_OP  (d, c, tt, 4, 0x0f0f0f0f);
  HPERM_OP (c,    tt, 2, 0xcccc0000);
  HPERM_OP (d,    tt, 2, 0xcccc0000);
  PERM_OP  (d, c, tt, 1, 0x55555555);
  PERM_OP  (c, d, tt, 8, 0x00ff00ff);
  PERM_OP  (d, c, tt, 1, 0x55555555);

  d = ((d & 0x000000ff) << 16)
    | ((d & 0x0000ff00) <<  0)
    | ((d & 0x00ff0000) >> 16)
    | ((c & 0xf0000000) >>  4);

  c = c & 0x0fffffff;

  #pragma unroll 16
  for (u32 i = 0; i < 16; i++)
  {
    c = c >> shifts3s0[i] | c << shifts3s1[i];
    d = d >> shifts3s0[i] | d << shifts3s1[i];

    c = c & 0x0fffffff;
    d = d & 0x0fffffff;

    const u32x c00 = (c >>  0) & 0x0000003f;
    const u32x c06 = (c >>  6) & 0x00383003;
    const u32x c07 = (c >>  7) & 0x0000003c;
    const u32x c13 = (c >> 13) & 0x0000060f;
    const u32x c20 = (c >> 20) & 0x00000001;

    u32x s = BOX (((c00 >>  0) & 0xff), 0, s_skb)
            | BOX (((c06 >>  0) & 0xff)
                  |((c07 >>  0) & 0xff), 1, s_skb)
            | BOX (((c13 >>  0) & 0xff)
                  |((c06 >>  8) & 0xff), 2, s_skb)
            | BOX (((c20 >>  0) & 0xff)
                  |((c13 >>  8) & 0xff)
                  |((c06 >> 16) & 0xff), 3, s_skb);

    const u32x d00 = (d >>  0) & 0x00003c3f;
    const u32x d07 = (d >>  7) & 0x00003f03;
    const u32x d21 = (d >> 21) & 0x0000000f;
    const u32x d22 = (d >> 22) & 0x00000030;

    u32x t = BOX (((d00 >>  0) & 0xff), 4, s_skb)
            | BOX (((d07 >>  0) & 0xff)
                  |((d00 >>  8) & 0xff), 5, s_skb)
            | BOX (((d07 >>  8) & 0xff), 6, s_skb)
            | BOX (((d21 >>  0) & 0xff)
                  |((d22 >>  0) & 0xff), 7, s_skb);

    Kc[i] = ((t << 16) | (s & 0x0000ffff));
    Kd[i] = ((s >> 16) | (t & 0xffff0000));
  }
}

static void transform_netntlmv1_key (const u32x w0, const u32x w1, u32x out[2])
{
  #ifdef VECT_SIZE1
  const uchar4 t0 = as_uchar4 (w0);
  const uchar4 t1 = as_uchar4 (w1);

  uchar4 k0;
  uchar4 k1;

  k0.s0 =                (t0.s0 >> 0);
  k0.s1 = (t0.s0 << 7) | (t0.s1 >> 1);
  k0.s2 = (t0.s1 << 6) | (t0.s2 >> 2);
  k0.s3 = (t0.s2 << 5) | (t0.s3 >> 3);
  k1.s0 = (t0.s3 << 4) | (t1.s0 >> 4);
  k1.s1 = (t1.s0 << 3) | (t1.s1 >> 5);
  k1.s2 = (t1.s1 << 2) | (t1.s2 >> 6);
  k1.s3 = (t1.s2 << 1);

  out[0] = as_uint (k0);
  out[1] = as_uint (k1);
  #endif

  #ifdef VECT_SIZE2
  const uchar8 t0 = as_uchar8 (w0);
  const uchar8 t1 = as_uchar8 (w1);

  uchar8 k0;
  uchar8 k1;

  k0.s0 =                (t0.s0 >> 0);
  k0.s1 = (t0.s0 << 7) | (t0.s1 >> 1);
  k0.s2 = (t0.s1 << 6) | (t0.s2 >> 2);
  k0.s3 = (t0.s2 << 5) | (t0.s3 >> 3);
  k1.s0 = (t0.s3 << 4) | (t1.s0 >> 4);
  k1.s1 = (t1.s0 << 3) | (t1.s1 >> 5);
  k1.s2 = (t1.s1 << 2) | (t1.s2 >> 6);
  k1.s3 = (t1.s2 << 1);

  k0.s4 =                (t0.s4 >> 0);
  k0.s5 = (t0.s4 << 7) | (t0.s5 >> 1);
  k0.s6 = (t0.s5 << 6) | (t0.s6 >> 2);
  k0.s7 = (t0.s6 << 5) | (t0.s7 >> 3);
  k1.s4 = (t0.s7 << 4) | (t1.s4 >> 4);
  k1.s5 = (t1.s4 << 3) | (t1.s5 >> 5);
  k1.s6 = (t1.s5 << 2) | (t1.s6 >> 6);
  k1.s7 = (t1.s6 << 1);

  out[0] = as_uint2 (k0);
  out[1] = as_uint2 (k1);
  #endif

  #ifdef VECT_SIZE4
  const uchar16 t0 = as_uchar16 (w0);
  const uchar16 t1 = as_uchar16 (w1);

  uchar16 k0;
  uchar16 k1;

  k0.s0 =                (t0.s0 >> 0);
  k0.s1 = (t0.s0 << 7) | (t0.s1 >> 1);
  k0.s2 = (t0.s1 << 6) | (t0.s2 >> 2);
  k0.s3 = (t0.s2 << 5) | (t0.s3 >> 3);
  k1.s0 = (t0.s3 << 4) | (t1.s0 >> 4);
  k1.s1 = (t1.s0 << 3) | (t1.s1 >> 5);
  k1.s2 = (t1.s1 << 2) | (t1.s2 >> 6);
  k1.s3 = (t1.s2 << 1);

  k0.s4 =                (t0.s4 >> 0);
  k0.s5 = (t0.s4 << 7) | (t0.s5 >> 1);
  k0.s6 = (t0.s5 << 6) | (t0.s6 >> 2);
  k0.s7 = (t0.s6 << 5) | (t0.s7 >> 3);
  k1.s4 = (t0.s7 << 4) | (t1.s4 >> 4);
  k1.s5 = (t1.s4 << 3) | (t1.s5 >> 5);
  k1.s6 = (t1.s5 << 2) | (t1.s6 >> 6);
  k1.s7 = (t1.s6 << 1);

  k0.s8 =                (t0.s8 >> 0);
  k0.s9 = (t0.s8 << 7) | (t0.s9 >> 1);
  k0.sa = (t0.s9 << 6) | (t0.sa >> 2);
  k0.sb = (t0.sa << 5) | (t0.sb >> 3);
  k1.s8 = (t0.sb << 4) | (t1.s8 >> 4);
  k1.s9 = (t1.s8 << 3) | (t1.s9 >> 5);
  k1.sa = (t1.s9 << 2) | (t1.sa >> 6);
  k1.sb = (t1.sa << 1);

  k0.sc =                (t0.sc >> 0);
  k0.sd = (t0.sc << 7) | (t0.sd >> 1);
  k0.se = (t0.sd << 6) | (t0.se >> 2);
  k0.sf = (t0.se << 5) | (t0.sf >> 3);
  k1.sc = (t0.sf << 4) | (t1.sc >> 4);
  k1.sd = (t1.sc << 3) | (t1.sd >> 5);
  k1.se = (t1.sd << 2) | (t1.se >> 6);
  k1.sf = (t1.se << 1);

  out[0] = as_uint4 (k0);
  out[1] = as_uint4 (k1);
  #endif
}

static void m05500m (__local u32 s_SPtrans[8][64], __local u32 s_skb[8][64], u32 w[16], const u32 pw_len, __global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset)
{
  /**
   * modifier
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  /**
   * salt
   */

  const u32 s0 = salt_bufs[salt_pos].salt_buf[0];
  const u32 s1 = salt_bufs[salt_pos].salt_buf[1];
  const u32 s2 = salt_bufs[salt_pos].salt_buf[2];

  u32x data[2];

  data[0] = s0;
  data[1] = s1;

  /**
   * loop
   */

  const u32 bf_loops = ceil ((float) bfs_cnt / VECT_DIV);

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < bf_loops; il_pos++)
  {
    const u32x w0r = words_buf_r[il_pos];

    const u32x w0 = w0l | w0r;

    u32x a = MD4M_A;
    u32x b = MD4M_B;
    u32x c = MD4M_C;
    u32x d = MD4M_D;

    #define w0_t w0
    #define w1_t w[ 1]
    #define w2_t w[ 2]
    #define w3_t w[ 3]
    #define w4_t w[ 4]
    #define w5_t w[ 5]
    #define w6_t w[ 6]
    #define w7_t w[ 7]
    #define w8_t w[ 8]
    #define w9_t w[ 9]
    #define wa_t w[10]
    #define wb_t w[11]
    #define wc_t w[12]
    #define wd_t w[13]
    #define we_t w[14]
    #define wf_t w[15]

    MD4_STEP (MD4_Fo, a, b, c, d, w0_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w1_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, w2_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, w3_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, w4_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w5_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, w6_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, w7_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, w8_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w9_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, wa_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, wb_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, wc_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, wd_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, we_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, wf_t, MD4C00, MD4S03);

    MD4_STEP (MD4_Go, a, b, c, d, w0_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w4_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, w8_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wc_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w1_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w5_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, w9_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wd_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w2_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w6_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, wa_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, we_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w3_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w7_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, wb_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wf_t, MD4C01, MD4S13);

    MD4_STEP (MD4_H , a, b, c, d, w0_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, w8_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w4_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wc_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w2_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, wa_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w6_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, we_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w1_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, w9_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w5_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wd_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w3_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, wb_t, MD4C02, MD4S21);

    if (allx (s2 != ((d + MD4M_D) >> 16))) continue;

    MD4_STEP (MD4_H , c, d, a, b, w7_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wf_t, MD4C02, MD4S23);

    a += MD4M_A;
    b += MD4M_B;
    c += MD4M_C;
    d += MD4M_D;

    /**
     * DES1
     */

    u32x key[2];

    transform_netntlmv1_key (a, b, key);

    u32x Kc[16];
    u32x Kd[16];

    _des_crypt_keysetup (key[0], key[1], Kc, Kd, s_skb);

    u32x iv1[2];

    _des_crypt_encrypt (iv1, data, Kc, Kd, s_SPtrans);

    /**
     * DES2
     */

    transform_netntlmv1_key (((b >> 24) | (c << 8)), ((c >> 24) | (d << 8)), key);

    _des_crypt_keysetup (key[0], key[1], Kc, Kd, s_skb);

    u32x iv2[2];

    _des_crypt_encrypt (iv2, data, Kc, Kd, s_SPtrans);

    /**
     * compare
     */

    const u32x r0 = iv1[0];
    const u32x r1 = iv1[1];
    const u32x r2 = iv2[0];
    const u32x r3 = iv2[1];

    #include VECT_COMPARE_M
  }
}

static void m05500s (__local u32 s_SPtrans[8][64], __local u32 s_skb[8][64], u32 w[16], const u32 pw_len, __global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset)
{
  /**
   * modifier
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  /**
   * salt
   */

  const u32 s0 = salt_bufs[salt_pos].salt_buf[0];
  const u32 s1 = salt_bufs[salt_pos].salt_buf[1];
  const u32 s2 = salt_bufs[salt_pos].salt_buf[2];

  u32x data[2];

  data[0] = s0;
  data[1] = s1;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * loop
   */

  const u32 bf_loops = ceil ((float) bfs_cnt / VECT_DIV);

  u32x w0l = w[0];

  for (u32 il_pos = 0; il_pos < bf_loops; il_pos++)
  {
    const u32x w0r = words_buf_r[il_pos];

    const u32x w0 = w0l | w0r;

    u32x a = MD4M_A;
    u32x b = MD4M_B;
    u32x c = MD4M_C;
    u32x d = MD4M_D;

    #define w0_t w0
    #define w1_t w[ 1]
    #define w2_t w[ 2]
    #define w3_t w[ 3]
    #define w4_t w[ 4]
    #define w5_t w[ 5]
    #define w6_t w[ 6]
    #define w7_t w[ 7]
    #define w8_t w[ 8]
    #define w9_t w[ 9]
    #define wa_t w[10]
    #define wb_t w[11]
    #define wc_t w[12]
    #define wd_t w[13]
    #define we_t w[14]
    #define wf_t w[15]

    MD4_STEP (MD4_Fo, a, b, c, d, w0_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w1_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, w2_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, w3_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, w4_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w5_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, w6_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, w7_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, w8_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, w9_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, wa_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, wb_t, MD4C00, MD4S03);
    MD4_STEP (MD4_Fo, a, b, c, d, wc_t, MD4C00, MD4S00);
    MD4_STEP (MD4_Fo, d, a, b, c, wd_t, MD4C00, MD4S01);
    MD4_STEP (MD4_Fo, c, d, a, b, we_t, MD4C00, MD4S02);
    MD4_STEP (MD4_Fo, b, c, d, a, wf_t, MD4C00, MD4S03);

    MD4_STEP (MD4_Go, a, b, c, d, w0_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w4_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, w8_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wc_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w1_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w5_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, w9_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wd_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w2_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w6_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, wa_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, we_t, MD4C01, MD4S13);
    MD4_STEP (MD4_Go, a, b, c, d, w3_t, MD4C01, MD4S10);
    MD4_STEP (MD4_Go, d, a, b, c, w7_t, MD4C01, MD4S11);
    MD4_STEP (MD4_Go, c, d, a, b, wb_t, MD4C01, MD4S12);
    MD4_STEP (MD4_Go, b, c, d, a, wf_t, MD4C01, MD4S13);

    MD4_STEP (MD4_H , a, b, c, d, w0_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, w8_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w4_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wc_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w2_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, wa_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w6_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, we_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w1_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, w9_t, MD4C02, MD4S21);
    MD4_STEP (MD4_H , c, d, a, b, w5_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wd_t, MD4C02, MD4S23);
    MD4_STEP (MD4_H , a, b, c, d, w3_t, MD4C02, MD4S20);
    MD4_STEP (MD4_H , d, a, b, c, wb_t, MD4C02, MD4S21);

    if (allx (s2 != ((d + MD4M_D) >> 16))) continue;

    MD4_STEP (MD4_H , c, d, a, b, w7_t, MD4C02, MD4S22);
    MD4_STEP (MD4_H , b, c, d, a, wf_t, MD4C02, MD4S23);

    a += MD4M_A;
    b += MD4M_B;
    c += MD4M_C;
    d += MD4M_D;

    /**
     * DES1
     */

    u32x key[2];

    transform_netntlmv1_key (a, b, key);

    u32x Kc[16];
    u32x Kd[16];

    _des_crypt_keysetup (key[0], key[1], Kc, Kd, s_skb);

    u32x iv1[2];

    _des_crypt_encrypt (iv1, data, Kc, Kd, s_SPtrans);

    /**
     * DES2
     */

    /*
    transform_netntlmv1_key (((b >> 24) | (c << 8)), ((c >> 24) | (d << 8)), key);

    _des_crypt_keysetup (key[0], key[1], Kc, Kd, s_skb);

    u32x iv2[2];

    _des_crypt_encrypt (iv2, data, Kc, Kd, s_SPtrans);
    */

    u32x iv2[2];

    iv2[0] = search[2];
    iv2[1] = search[3];

    /**
     * compare
     */

    const u32x r0 = iv1[0];
    const u32x r1 = iv1[1];
    const u32x r2 = iv2[0];
    const u32x r3 = iv2[1];

    #include VECT_COMPARE_S
  }
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_m04 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * base
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = 0;
  w[ 5] = 0;
  w[ 6] = 0;
  w[ 7] = 0;
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = pws[gid].i[14];
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len;

  /**
   * sbox, kbox
   */

  __local u32 s_SPtrans[8][64];
  __local u32 s_skb[8][64];

  s_SPtrans[0][lid] = c_SPtrans[0][lid];
  s_SPtrans[1][lid] = c_SPtrans[1][lid];
  s_SPtrans[2][lid] = c_SPtrans[2][lid];
  s_SPtrans[3][lid] = c_SPtrans[3][lid];
  s_SPtrans[4][lid] = c_SPtrans[4][lid];
  s_SPtrans[5][lid] = c_SPtrans[5][lid];
  s_SPtrans[6][lid] = c_SPtrans[6][lid];
  s_SPtrans[7][lid] = c_SPtrans[7][lid];

  s_skb[0][lid] = c_skb[0][lid];
  s_skb[1][lid] = c_skb[1][lid];
  s_skb[2][lid] = c_skb[2][lid];
  s_skb[3][lid] = c_skb[3][lid];
  s_skb[4][lid] = c_skb[4][lid];
  s_skb[5][lid] = c_skb[5][lid];
  s_skb[6][lid] = c_skb[6][lid];
  s_skb[7][lid] = c_skb[7][lid];

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * main
   */

  m05500m (s_SPtrans, s_skb, w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_scryptV_buf, bitmap_mask, bitmap_shift1, bitmap_shift2, salt_pos, loop_pos, loop_cnt, bfs_cnt, digests_cnt, digests_offset);
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_m08 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * base
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = pws[gid].i[14];
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len;

  /**
   * sbox, kbox
   */

  __local u32 s_SPtrans[8][64];
  __local u32 s_skb[8][64];

  s_SPtrans[0][lid] = c_SPtrans[0][lid];
  s_SPtrans[1][lid] = c_SPtrans[1][lid];
  s_SPtrans[2][lid] = c_SPtrans[2][lid];
  s_SPtrans[3][lid] = c_SPtrans[3][lid];
  s_SPtrans[4][lid] = c_SPtrans[4][lid];
  s_SPtrans[5][lid] = c_SPtrans[5][lid];
  s_SPtrans[6][lid] = c_SPtrans[6][lid];
  s_SPtrans[7][lid] = c_SPtrans[7][lid];

  s_skb[0][lid] = c_skb[0][lid];
  s_skb[1][lid] = c_skb[1][lid];
  s_skb[2][lid] = c_skb[2][lid];
  s_skb[3][lid] = c_skb[3][lid];
  s_skb[4][lid] = c_skb[4][lid];
  s_skb[5][lid] = c_skb[5][lid];
  s_skb[6][lid] = c_skb[6][lid];
  s_skb[7][lid] = c_skb[7][lid];

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * main
   */

  m05500m (s_SPtrans, s_skb, w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_scryptV_buf, bitmap_mask, bitmap_shift1, bitmap_shift2, salt_pos, loop_pos, loop_cnt, bfs_cnt, digests_cnt, digests_offset);
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_m16 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_s04 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * base
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = 0;
  w[ 5] = 0;
  w[ 6] = 0;
  w[ 7] = 0;
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = pws[gid].i[14];
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len;

  /**
   * sbox, kbox
   */

  __local u32 s_SPtrans[8][64];
  __local u32 s_skb[8][64];

  s_SPtrans[0][lid] = c_SPtrans[0][lid];
  s_SPtrans[1][lid] = c_SPtrans[1][lid];
  s_SPtrans[2][lid] = c_SPtrans[2][lid];
  s_SPtrans[3][lid] = c_SPtrans[3][lid];
  s_SPtrans[4][lid] = c_SPtrans[4][lid];
  s_SPtrans[5][lid] = c_SPtrans[5][lid];
  s_SPtrans[6][lid] = c_SPtrans[6][lid];
  s_SPtrans[7][lid] = c_SPtrans[7][lid];

  s_skb[0][lid] = c_skb[0][lid];
  s_skb[1][lid] = c_skb[1][lid];
  s_skb[2][lid] = c_skb[2][lid];
  s_skb[3][lid] = c_skb[3][lid];
  s_skb[4][lid] = c_skb[4][lid];
  s_skb[5][lid] = c_skb[5][lid];
  s_skb[6][lid] = c_skb[6][lid];
  s_skb[7][lid] = c_skb[7][lid];

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * main
   */

  m05500s (s_SPtrans, s_skb, w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_scryptV_buf, bitmap_mask, bitmap_shift1, bitmap_shift2, salt_pos, loop_pos, loop_cnt, bfs_cnt, digests_cnt, digests_offset);
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_s08 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * base
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);

  u32 w[16];

  w[ 0] = pws[gid].i[ 0];
  w[ 1] = pws[gid].i[ 1];
  w[ 2] = pws[gid].i[ 2];
  w[ 3] = pws[gid].i[ 3];
  w[ 4] = pws[gid].i[ 4];
  w[ 5] = pws[gid].i[ 5];
  w[ 6] = pws[gid].i[ 6];
  w[ 7] = pws[gid].i[ 7];
  w[ 8] = 0;
  w[ 9] = 0;
  w[10] = 0;
  w[11] = 0;
  w[12] = 0;
  w[13] = 0;
  w[14] = pws[gid].i[14];
  w[15] = 0;

  const u32 pw_len = pws[gid].pw_len;

  /**
   * sbox, kbox
   */

  __local u32 s_SPtrans[8][64];
  __local u32 s_skb[8][64];

  s_SPtrans[0][lid] = c_SPtrans[0][lid];
  s_SPtrans[1][lid] = c_SPtrans[1][lid];
  s_SPtrans[2][lid] = c_SPtrans[2][lid];
  s_SPtrans[3][lid] = c_SPtrans[3][lid];
  s_SPtrans[4][lid] = c_SPtrans[4][lid];
  s_SPtrans[5][lid] = c_SPtrans[5][lid];
  s_SPtrans[6][lid] = c_SPtrans[6][lid];
  s_SPtrans[7][lid] = c_SPtrans[7][lid];

  s_skb[0][lid] = c_skb[0][lid];
  s_skb[1][lid] = c_skb[1][lid];
  s_skb[2][lid] = c_skb[2][lid];
  s_skb[3][lid] = c_skb[3][lid];
  s_skb[4][lid] = c_skb[4][lid];
  s_skb[5][lid] = c_skb[5][lid];
  s_skb[6][lid] = c_skb[6][lid];
  s_skb[7][lid] = c_skb[7][lid];

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * main
   */

  m05500s (s_SPtrans, s_skb, w, pw_len, pws, rules_buf, combs_buf, words_buf_r, tmps, hooks, bitmaps_buf_s1_a, bitmaps_buf_s1_b, bitmaps_buf_s1_c, bitmaps_buf_s1_d, bitmaps_buf_s2_a, bitmaps_buf_s2_b, bitmaps_buf_s2_c, bitmaps_buf_s2_d, plains_buf, digests_buf, hashes_shown, salt_bufs, esalt_bufs, d_return_buf, d_scryptV_buf, bitmap_mask, bitmap_shift1, bitmap_shift2, salt_pos, loop_pos, loop_cnt, bfs_cnt, digests_cnt, digests_offset);
}

__kernel void __attribute__((reqd_work_group_size (64, 1, 1))) m05500_s16 (__global pw_t *pws, __global gpu_rule_t *rules_buf, __global comb_t *combs_buf, __global u32x * words_buf_r, __global void *tmps, __global void *hooks, __global u32 *bitmaps_buf_s1_a, __global u32 *bitmaps_buf_s1_b, __global u32 *bitmaps_buf_s1_c, __global u32 *bitmaps_buf_s1_d, __global u32 *bitmaps_buf_s2_a, __global u32 *bitmaps_buf_s2_b, __global u32 *bitmaps_buf_s2_c, __global u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global digest_t *digests_buf, __global u32 *hashes_shown, __global salt_t *salt_bufs, __global void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 bfs_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
}
