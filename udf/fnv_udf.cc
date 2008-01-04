/* This file implements a 64-bit FNV-1 hash UDF (user-defined function) for
 * MySQL.  The function accepts any number of arguments and returns a 64-bit
 * unsigned integer.  MySQL actually interprets the result as a signed integer,
 * but you should ignore that.  I chose not to return the number as a
 * hexadecimal string because using an integer makes it possible to use it
 * efficiently with BIT_XOR().
 *
 * The function never returns NULL, even when you give it NULL arguments.
 *
 * To compile and install, execute the following commands.  The function name
 * fnv_64 in the mysql command is case-sensitive!  (Of course, when you actually
 * call the function, it is case-insensitive just like any other SQL function).
 *
 * gcc -fPIC -Wall -I/usr/include/mysql -shared -o fnv_udf.so fnv_udf.cc
 * cp fnv_udf.so /lib
 * mysql mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'fnv_udf.so'"
 *
 */

/* The following header is from hash_64.c:
 *
 * hash_64 - 64 bit Fowler/Noll/Vo-0 hash code
 *
 * @(#) $Revision: 1.8 $
 * @(#) $Id: hash_64.c,v 1.8 2003/10/03 20:37:04 chongo Exp $
 * @(#) $Source: /usr/local/src/cmd/fnv/RCS/hash_64.c,v $
 *
 ***
 *
 * Fowler/Noll/Vo hash
 *
 * The basis of this hash algorithm was taken from an idea sent
 * as reviewer comments to the IEEE POSIX P1003.2 committee by:
 *
 *      Phong Vo (http://www.research.att.com/info/kpv/)
 *      Glenn Fowler (http://www.research.att.com/~gsf/)
 *
 * In a subsequent ballot round:
 *
 *      Landon Curt Noll (http://www.isthe.com/chongo/)
 *
 * improved on their algorithm.  Some people tried this hash
 * and found that it worked rather well.  In an EMail message
 * to Landon, they named it the ``Fowler/Noll/Vo'' or FNV hash.
 *
 * FNV hashes are designed to be fast while maintaining a low
 * collision rate. The FNV speed allows one to quickly hash lots
 * of data while maintaining a reasonable collision rate.  See:
 *
 *      http://www.isthe.com/chongo/tech/comp/fnv/index.html
 *
 * for more details as well as other forms of the FNV hash.
 *
 ***
 *
 * NOTE: The FNV-0 historic hash is not recommended.  One should use
 *	 the FNV-1 hash instead.
 *
 * To use the 64 bit FNV-0 historic hash, pass FNV0_64_INIT as the
 * Fnv64_t hashval argument to fnv_64_buf() or fnv_64_str().
 *
 * To use the recommended 64 bit FNV-1 hash, pass FNV1_64_INIT as the
 * Fnv64_t hashval argument to fnv_64_buf() or fnv_64_str().
 *
 ***
 *
 * Please do not copyright this code.  This code is in the public domain.
 *
 * LANDON CURT NOLL DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL LANDON CURT NOLL BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
 * USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 * By:
 *	chongo <Landon Curt Noll> /\oo/\
 *      http://www.isthe.com/chongo/
 *
 * Share and Enjoy!	:-)
 */

#include <my_global.h>
#include <my_sys.h>
#include <mysql.h>
#include <ctype.h>

/* On the first call, use this as the initial_value. */
#define HASH_64_INIT 0x84222325cbf29ce4ULL
/* Default for NULLs, just so the result is never NULL. */
#define HASH_NULL_DEFAULT 0x0a0b0c0d
/* Magic number for the hashing. */
static const ulonglong FNV_64_PRIME = 0x100000001b3ULL;

/* Prototypes */

extern "C" {
   ulonglong hash64(const void *buf, size_t len, ulonglong hval);
   my_bool fnv_64_init( UDF_INIT* initid, UDF_ARGS* args, char* message );
   ulonglong fnv_64(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error );
}

/* Implementations */

ulonglong hash64(const void *buf, size_t len, ulonglong hval)
{
   const unsigned char *bp = (const unsigned char*)buf;
   const unsigned char *be = bp + len;

   /* FNV-1 hash each octet of the buffer */
   for (; bp != be; ++bp) {
      /* multiply by the 64 bit FNV magic prime mod 2^64 */
      hval *= FNV_64_PRIME;
      /* xor the bottom with the current octet */
      hval ^= (ulonglong)*bp;
   }

   return hval;
}

/*
** FNV_64 function
*/
my_bool
fnv_64_init( UDF_INIT* initid, UDF_ARGS* args, char* message )
{
   initid->maybe_null = 0;      /* The result will never be NULL */
   return 0;
}


ulonglong
fnv_64(UDF_INIT *initid, UDF_ARGS *args, char *is_null, char *error )
{

   uint null_default = HASH_NULL_DEFAULT;
   ulonglong result  = HASH_64_INIT;
   uint i            = 0;

   for ( ; i < args->arg_count; ++i ) {
      if ( !args->maybe_null[i] ) {
         result
            = hash64((const void*)args->args[i], args->lengths[i], result);
      }
      else {
         result
            = hash64((const void*)&null_default, sizeof(null_default), result);
      }
   }
   return result;
}
