/*
    File: mpPackage.h
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

#ifndef _clasp_mpPackage_H
#define _clasp_mpPackage_H
#include <clasp/core/foundation.h>
#include <clasp/core/mpPackage.fwd.h>

namespace mp {
  FORWARD(Process);
  FORWARD(Mutex);
  FORWARD(RecursiveMutex);
  FORWARD(ConditionVariable);
};


namespace mp {
#ifdef CLASP_THREADS
  /*! Keep track of binding indices for symbols */
  extern GlobalMutex global_BindingIndexPoolMutex;
  extern std::vector<size_t> global_BindingIndexPool;
  extern std::atomic<size_t> global_LastBindingIndex;
#endif
};

#ifdef CLASP_THREADS
template <typename T>
struct RAIILock {
RAIILock(T& m) : _Mutex(m) {
  this->_Mutex.lock();
};
  ~RAIILock() {
    this->_Mutex.unlock();
  }
  T& _Mutex;
};
#endif


namespace mp {
  inline core::T_sp atomic_get_and_set_to_Nil(std::atomic<core::T_sp>& slot) noexcept {
      core::T_sp old;
      do {
        old = slot.load();
      } while (!slot.compare_exchange_weak(old,_Nil<core::T_O>()));
      return old;
    }
  inline void atomic_push(std::atomic<core::T_sp>& slot, core::T_sp object) {
      core::Cons_sp cons = core::Cons_O::create(object,_Nil<core::T_O>());
      core::T_sp tcons = cons;
      core::T_sp car;
      do {
        car = slot.load();
        cons->rplaca(car);
      } while (!slot.compare_exchange_weak(car,tcons));
    }

};

namespace mp {
    
  class Process_O : public core::CxxObject_O {
    LISP_CLASS(mp, MpPkg, Process_O, "Process",core::CxxObject_O);
  public:
    CL_LISPIFY_NAME("make_process");
    CL_LAMBDA(name function &optional arguments (stack-size 8388608))
    CL_DEF_CLASS_METHOD static Process_sp make_process(core::T_sp name, core::T_sp function, core::T_sp arguments, size_t stack_size) {
      GC_ALLOCATE_VARIADIC(Process_O,p,name,function,arguments,stack_size);
      return p;
    };
  public:
    core::T_sp  _Name;
    core::T_sp _Function;
    core::T_sp _Arguments;
    core::T_sp  _ReturnValuesList;
    size_t _StackSize;
    pthread_t _Thread;
//    pthread_mutex_t  _ExitBarrier;
  public:
  Process_O(core::T_sp name, core::T_sp function, core::T_sp arguments, size_t stack_size=8*1024*1024) : _Name(name), _Function(function), _Arguments(arguments), _ReturnValuesList(_Nil<core::T_O>()), _StackSize(stack_size) {};
    
    int enable() {
      pthread_attr_t attr;
      int result;
      result = pthread_attr_init(&attr);
      result = pthread_attr_setstacksize(&attr,this->_StackSize);
      if (result!=0) return result;
      result = pthread_create(&this->_Thread, &attr, start_thread, (void*)this );
      pthread_attr_destroy(&attr);
      return result;
    }
  };
};

template <>
struct gctools::GCInfo<mp::Mutex_O> {
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = true;
  static GCInfo_policy constexpr Policy = normal;
};

namespace mp {

  FORWARD(Mutex);
  class Mutex_O : public core::CxxObject_O {
    LISP_CLASS(mp, MpPkg, Mutex_O, "Mutex",core::CxxObject_O);
  public:
    CL_LISPIFY_NAME("make_mutex");
    CL_LAMBDA(&optional name)
      CL_DEF_CLASS_METHOD static Mutex_sp make_mutex(core::T_sp name) {
      GC_ALLOCATE_VARIADIC(Mutex_O,l,name,false);
      return l;
    };
  public:
    core::T_sp  _Name;
    Mutex _Mutex;
  Mutex_O(core::T_sp name, bool recursive) : _Name(name), _Mutex(recursive) {};
    CL_DEFMETHOD bool lock(bool waitp) { return this->_Mutex.lock(waitp); };
    CL_DEFMETHOD void unlock() { return this->_Mutex.unlock(); };
  };
};


template <>
struct gctools::GCInfo<mp::RecursiveMutex_O> {
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = true;
  static GCInfo_policy constexpr Policy = normal;
};

namespace mp {

  FORWARD(RecursiveMutex);
  class RecursiveMutex_O : public Mutex_O {
    LISP_CLASS(mp, MpPkg, RecursiveMutex_O, "RecursiveMutex",Mutex_O);
  public:
    CL_LAMBDA(&optional name);
    CL_DEF_CLASS_METHOD static RecursiveMutex_sp make_recursive_mutex(core::T_sp name) {
      GC_ALLOCATE_VARIADIC(RecursiveMutex_O,l, name);
      return l;
    };
  RecursiveMutex_O(core::T_sp name) :Mutex_O(name,true) {};
  };

};

#if 0
template <>
struct gctools::GCInfo<mp::ConditionVariable_O> {
  static bool constexpr NeedsInitialization = false;
  static bool constexpr NeedsFinalization = true;
  static GCInfo_policy constexpr Policy = normal;
};

namespace mp {

  FORWARD(ConditionVariable);
  class ConditionVariable_O : public core::CxxObject_O {
    LISP_CLASS(mp, MpPkg, ConditionVariable_O, "ConditionVariable",core::CxxObject_O);
  public:
    ConditionVariable_sp make_condition_variable();
    CL_LAMBDA(&optional name)
    CL_DEF_CLASS_METHOD static ConditionVariable_sp make_ConditionVariable(core::T_sp name) {
      GC_ALLOCATE_VARIADIC(ConditionVariable_O,l,name);
      return l;
    };
  public:
    ConditionVariable _ConditionVariable;
    core::T_sp _Name;
  ConditionVariable_O(core::T_sp name) : _Name(name) {};
//    CL_DEFMETHOD void notify_one() { this->_ConditionVariable.notify_one(); };
//    CL_DEFMETHOD void notify_all() { this->_ConditionVariable.notify_all(); };
//    CL_DEFMETHOD void wait(Mutex_sp m) { this->_ConditionVariable.wait(m->_UniqueMutex); };
  };

};
#endif

#endif
