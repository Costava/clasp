/*
    File: bignum.h
*/

/*
Copyright (c) 2014, Christian E. Schafmeister

CLASP is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

See directory 'clasp/licenses' for full details.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
/* -^- */
#ifndef _core_bignum_H_
#define _core_bignum_H_

#include <clasp/core/clasp_gmpxx.h>
#include <clasp/core/object.h>
#include <clasp/core/numbers.h>
#include <clasp/core/bignum.fwd.h>

namespace core {
class Bignum_O;
}

template <>
struct gctools::GCInfo<core::Bignum_O> {
  static bool constexpr CanAllocateWithNoArguments = true;
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = true;
  static GCInfo_policy constexpr Policy = normal;
};

namespace core {
class Bignum_O : public Integer_O {
  LISP_CLASS(core, ClPkg, Bignum_O, "Bignum",Integer_O);
  //    DECLARE_ARCHIVE();
public: // Simple default ctor/dtor
  DEFAULT_CTOR_DTOR(Bignum_O);

public: // ctor/dtor for classes with shared virtual base
        //    explicit Bignum_O(core::Instance_sp const& mc) : T_O(mc), Integer(mc) {};
        //    virtual ~Bignum_O() {};
public:
  //	void initialize();

private: // instance variables here
  Bignum _value;

public: // Functions here
  static Bignum_sp make(const string &value_in_string);

  static Bignum_sp create( gc::Fixnum i )
  {
    GC_ALLOCATE(Bignum_O, b);
    b->_value = static_cast<long>(i);
    return b;
  };

  static Bignum_sp create( mpz_class v )
  {
    GC_ALLOCATE(Bignum_O, b);
    b->_value = v;
    return b;
  };

#if !defined( CLASP_FIXNUM_IS_INT64 )

  static Bignum_sp create( int64_t v )
  {
    GC_ALLOCATE(Bignum_O, b);
    b->_value = (signed long int) v;
    return b;
  };

#endif

  static Bignum_sp create( uint64_t v )
  {
    GC_ALLOCATE(Bignum_O, b);
    b->_value = (unsigned long int) v;
    return b;
  };

#if !defined( CLASP_LONG_LONG_IS_INT64 )

  static Bignum_sp create( long long v )
  {
    GC_ALLOCATE(Bignum_O, b);
#ifdef _TARGET_OS_DARWIN
    b->_value = (long long)v;
#else
    b->_value = (int64_t)v;
#endif
    return b;
  };

#endif

#if !defined( CLASP_UNSIGNED_LONG_LONG_IS_UINT64 )

  static Bignum_sp create( unsigned long long v )
  {
    GC_ALLOCATE(Bignum_O, b);
#ifdef _TARGET_OS_DARWIN
    b->_value = (unsigned long long)v;
#else
    b->_value = (uint64_t)v;
#endif
    return b;
  };

#endif

 public:

  NumberType number_type_() const override { return number_Bignum; };

  mpz_class mpz() const { return this->_value; };
  mpz_class& mpz_ref() { return this->_value; };

  string __repr__() const override;

  Number_sp signum_() const override;

  /*! Return true if the number fits in a signed int */
  bool fits_sint_p();

  //virtual Number_sp copy() const;
  string description() const override {
    stringstream ss;
    ss << this->_value;
    return ss.str();
  };
  void setFixnum(gctools::Fixnum val) { this->_value = static_cast<long>(val); };
  Bignum get() const;
  Bignum get_or_if_nil_default(Bignum default_value) const;
  Number_sp abs_() const override;
  Number_sp log1_() const override;
  Number_sp sqrt_() const override;
  Number_sp reciprocal_() const override;
  Number_sp rational_() const final { return this->asSmartPtr(); };

  virtual bool zerop_() const override { return ((this->_value == 0)); }
  virtual bool plusp_() const override { return ((this->_value > 0)); }
  virtual bool minusp_() const override { return ((this->_value < 0)); }

  virtual Number_sp negate_() const override {
    return Integer_O::create(-this->_value);
  }

  virtual Number_sp oneMinus_() const override {
    return Integer_O::create(this->_value - 1);
  }
  virtual Number_sp onePlus_() const override {
    return Integer_O::create(this->_value + 1);
  }

  virtual gc::Fixnum bit_length_() const override;

  /*! Return the value shifted by BITS bits.
	  If BITS < 0 shift right, if BITS >0 shift left. */
  Integer_sp shift_(gc::Fixnum bits) const override;

  //	virtual	bool	eqn(T_sp obj) const;
  virtual bool eql_(T_sp obj) const override;

 public:
  virtual string valueAsString() const {
    stringstream ss;
    ss << this->_value;
    return ss.str();
  };
  virtual void setFromString(const string &strVal);

  // --- TRANSLATION METHODS ---

  virtual short as_short() const override;
  virtual unsigned short as_ushort() const override;

  virtual int as_int() const override;
  virtual unsigned int as_uint() const override;

  virtual long as_long() const override;
  virtual unsigned long as_ulong() const override;

  virtual long long as_longlong() const override;
  virtual unsigned long long as_ulonglong() const override;

  virtual int8_t as_int8_t() const override;
  virtual uint8_t as_uint8_t() const override;

  virtual int16_t as_int16_t() const override;
  virtual uint16_t as_uint16_t() const override;

  virtual int32_t as_int32_t() const override;
  virtual uint32_t as_uint32_t() const override;

  virtual int64_t as_int64_t() const override;
  virtual uint64_t as_uint64_t() const override;

  virtual uintptr_t as_uintptr_t() const override;
  virtual ptrdiff_t as_ptrdiff_t() const override;
  virtual size_t as_size_t() const override;
  virtual ssize_t as_ssize_t() const override;

  // --- THESE FUNCTIONS RETAINED FOR COMPATIBILITY ---
  // TODO: Code Cleanup: Replace with newer translation functions above
  // frgo, 2016-09-06

  virtual gc::Fixnum as_int_() const override;
  virtual int64_t as_int64_() const override;
  virtual uint64_t as_uint64_() const override;
  string as_uint64_string() const;

  gc::Fixnum popcount() const;
  Rational_sp ratdivide(Integer_sp) const override;
  virtual LongLongInt as_LongLongInt_() const override;
  virtual unsigned long long as_unsigned_long_long_() const;
  virtual float as_float_() const override;
  virtual double as_double_() const override;
  virtual LongFloat as_long_float_() const override;

  // --- END OF TRANSLATION METHODS ---

  void sxhash_(HashGenerator &hg) const override;

  virtual bool evenp_() const override { return (mpz_get_ui(this->_value.get_mpz_t()) & 1) == 0; };
  virtual bool oddp_() const override { return (mpz_get_ui(this->_value.get_mpz_t()) & 1) != 0; };

}; // Bignum class

}; // core namespace

namespace core {

  Integer_mv big_ceiling(Bignum_sp a, Bignum_sp b);
  Integer_mv big_floor(Bignum_sp a, Bignum_sp b);

  inline Integer_sp _clasp_big_register_normalize(Bignum_sp x) {
    return Integer_O::create(x->mpz_ref());
  }

  inline Integer_sp _clasp_big_floor(Bignum_sp a, Bignum_sp b, Real_sp *rP) {
    Integer_mv res_mv = big_floor(a, b);
    *rP = gc::As<Real_sp>(res_mv.valueGet_(1));
    return res_mv;
  };

  inline Integer_sp _clasp_big_ceiling(Bignum_sp a, Bignum_sp b, Real_sp *rP) {
    Integer_mv res_mv = big_ceiling(a, b);
    *rP = gc::As<Real_sp>(res_mv.valueGet_(1));
    return res_mv;
  }

  inline double _clasp_big_to_double(Bignum_sp a) {
    return a->as_double_();
  }

  void clasp_big_register_free(Bignum_sp x);

  Integer_sp _clasp_fix_divided_by_big(const Fixnum x, const Bignum_sp y);
  Integer_sp _clasp_big_divided_by_fix(const Bignum_sp x, const Fixnum y);
  Integer_sp _clasp_big_divided_by_big(const Bignum_sp x, const Bignum_sp y);

  Integer_sp _clasp_big_gcd(Bignum_sp x, Bignum_sp y);

#define CLASP_BIGNUM_SIZE(x) ((x)->_mp_size)
#define CLASP_BIGNUM_ABS_SIZE(x) \
  (CLASP_BIGNUM_SIZE(x) < 0 ? -CLASP_BIGNUM_SIZE(x) : CLASP_BIGNUM_SIZE(x))

 };


namespace core {
FORWARD(TheNextBignum);
};


template <>
struct gctools::GCInfo<core::TheNextBignum_O> {
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = false;
  static GCInfo_policy constexpr Policy = atomic;
};

namespace core {
class TheNextBignum_O : public Integer_O {
  LISP_CLASS(core, CorePkg, TheNextBignum_O, "TheNextBignum",Integer_O);
public:
  TheNextBignum_O(int64_t signed_length, mp_limb_t initialElement=0, bool initialElementSupplied=false,size_t initialContentsSize=0, const mp_limb_t* initialContents=NULL) : _limbs(signed_length,initialElement,initialElementSupplied,initialContentsSize,initialContents) {
  }
private: // instance variables here
  gctools::GCArraySignedLength_moveable<mp_limb_t> _limbs;

public: // Functions here
  static TheNextBignum_sp create( int64_t signed_number_of_limbs, mp_limb_t initialElement=0, bool initialElementSupplied=false, size_t initialContentsSize=0, const mp_limb_t* initialContents=NULL)
  {
    GC_ALLOCATE_VARIADIC(TheNextBignum_O,b,signed_number_of_limbs,initialElement,initialElementSupplied,initialContentsSize,initialContents);
    return b;
  };

  mp_size_t length() const { return _limbs.signedLength(); }
  const mp_limb_t* limbs() const { return &(_limbs._Data[0]);}

  NumberType number_type_() const override { return number_NextBignum; };

  void sxhash_(HashGenerator &hg) const;

  string __repr__() const override;

  Number_sp signum_() const override;
  Number_sp abs_() const override;

  Number_sp reciprocal_() const override;
  Number_sp rational_() const final { return this->asSmartPtr(); };
  virtual float as_float_() const override;
  virtual double as_double_() const override;
  virtual LongFloat as_long_float_() const override;

  virtual bool zerop_() const override { return false; }
  virtual bool plusp_() const override { return (this->length() > 0); }
  virtual bool minusp_() const override { return (this->length() < 0); }
  gc::Fixnum popcount() const;
  Rational_sp ratdivide(Integer_sp) const override;
  virtual gc::Fixnum bit_length_() const override;

  virtual bool eql_(T_sp obj) const override;
  
}; // TheNextBignum class

Integer_sp core__next_fmul(TheNextBignum_sp, Fixnum);
TheNextBignum_sp core__next_mul(TheNextBignum_sp, TheNextBignum_sp);
TheNextBignum_sp core__next_lshift(TheNextBignum_sp, Fixnum);
Integer_sp core__next_rshift(TheNextBignum_sp, Fixnum);
T_mv core__next_truncate(TheNextBignum_sp, TheNextBignum_sp);
Integer_sp fix_divided_by_next(Fixnum, TheNextBignum_sp);
T_mv core__next_ftruncate(TheNextBignum_sp, Fixnum);
Integer_sp core__next_gcd(TheNextBignum_sp, TheNextBignum_sp);
Integer_sp core__next_fgcd(TheNextBignum_sp, Fixnum);
Integer_sp core__next_add(TheNextBignum_sp, TheNextBignum_sp);
Integer_sp core__next_fadd(TheNextBignum_sp, Fixnum);

}; // core namespace


#endif /* _bignum_H_ */
