/*
    File: mpPackage.cc
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

#include <clasp/core/foundation.h>
#include <clasp/core/object.h>
#include <clasp/core/lisp.h>
#include <clasp/gctools/memoryManagement.h>
#include <clasp/core/symbol.h>
#include <clasp/core/mpPackage.h>
#include <clasp/core/multipleValues.h>
#include <clasp/core/package.h>
#include <clasp/core/evaluator.h>





namespace mp {



#ifdef CLASP_THREADS
std::atomic<size_t> global_LastBindingIndex = ATOMIC_VAR_INIT(0);
GlobalMutex global_BindingIndexPoolMutex(false);
std::vector<size_t> global_BindingIndexPool;
#endif


SYMBOL_SC_(MpPkg, aSingleMpSymbol);
SYMBOL_EXPORT_SC_(MpPkg, roo);

struct SafeRegisterDeregisterProcessWithLisp {
  Process_sp _Process;
  SafeRegisterDeregisterProcessWithLisp(Process_sp p) : _Process(p)
  {
    _lisp->add_process(_Process);
  }
  ~SafeRegisterDeregisterProcessWithLisp() {
    _lisp->remove_process(_Process);
  }
};

void* start_thread(void* claspProcess) {
  Process_O* my_claspProcess = (Process_O*)claspProcess;
  Process_sp p(my_claspProcess);
  SafeRegisterDeregisterProcessWithLisp reg(p);
  void* stack_base;
  core::ThreadLocalState my_thread_local_state(&stack_base);
  printf("%s:%d entering start_thread  &my_thread -> %p \n", __FILE__, __LINE__, (void*)&my_thread);
  my_thread = &my_thread_local_state;
  my_thread->initialize_thread();
#if 0
#ifdef USE_BOEHM
  GC_stack_base gc_stack_base;
  GC_get_stack_base(&gc_stack_base);
  GC_register_my_thread(&gc_stack_base);
#endif
#endif
#ifdef USE_MPS
  printf("%s:%d Handle threads for MPS\n", __FILE__, __LINE__ );
  abort();
#endif
//  gctools::register_thread(process,stack_base);
  core::List_sp args = my_claspProcess->_Arguments;
  core::T_mv result_mv = core::eval::applyLastArgsPLUSFirst(my_claspProcess->_Function,args);
  core::T_sp result0 = result_mv;
  core::List_sp result_list = _Nil<core::T_O>();
  for ( int i=result_mv.number_of_values(); i>0; --i ) {
    result_list = core::Cons_O::create(result_mv.valueGet_(i),result_list);
  }
  result_list = core::Cons_O::create(result0,result_list);
  my_claspProcess->_ReturnValuesList = result_list;
//  gctools::unregister_thread(process);
  printf("%s:%d leaving start_thread\n", __FILE__, __LINE__);
#if 0
#ifdef USE_BOEHM
  GC_unregister_my_thread();
#endif
#endif
#ifdef USE_MPS
  printf("%s:%d Handle threads for MPS\n", __FILE__, __LINE__ );
  abort();
#endif
  printf("%s:%d  really leaving start_thread\n", __FILE__, __LINE__ );
  return NULL;
}



CL_DEFUN int mp__process_enable(Process_sp process)
{
  return process->enable();
};

CL_DEFUN core::List_sp mp__all_processes() {
  return _lisp->processes();
}

CL_DEFUN Process_sp mp__current_process() {
  return my_thread->_Process;
}

CL_DEFUN core::T_sp mp__process_name(Process_sp p) {
  return p->_Name;
}

CL_DEFUN core::T_sp mp__mutex_name(Mutex_sp m) {
  return m->_Name;
}

CL_DEFUN bool mp__get_lock(Mutex_sp m, bool waitp) {
  return m->lock(waitp);
}

CL_DEFUN bool mp__giveup_lock(Mutex_sp m) {
   m->unlock();
   return true;
}

};
