
/*
    File: gc_interface.cc
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
#define DEBUG_LEVEL_FULL
typedef bool _Bool;
#ifndef SCRAPING // #endif at bottom
#include <clasp/core/foundation.h>
#include <type_traits>
//#include <llvm/Support/system_error.h>
#include <llvm/ExecutionEngine/GenericValue.h>
//#include <llvm/ExecutionEngine/SectionMemoryManager.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/LinkAllPasses.h>
#include <llvm/CodeGen/LinkAllCodegenComponents.h>
#include <llvm/Bitcode/BitcodeReader.h>
#include <llvm/Bitcode/BitcodeWriter.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Constants.h>
#include <llvm/IR/GlobalVariable.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/CallingConv.h>
#include <llvm/IR/BasicBlock.h>
#include <llvm/IR/Instructions.h>
#include <llvm/Transforms/Instrumentation.h>
#include <llvm/Transforms/Instrumentation/ThreadSanitizer.h>
#include <llvm/Transforms/IPO.h>
#include <llvm/IR/InlineAsm.h>
#include <llvm/CodeGen/TargetPassConfig.h>
#include <llvm/Support/FormattedStream.h>
#include <llvm/Support/TargetRegistry.h>
#include <llvm/Support/MathExtras.h>
#include <llvm/Pass.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/IR/Verifier.h>
#include "llvm/IR/AssemblyAnnotationWriter.h" // will be llvm/IR
//#include <llvm/IR/PrintModulePass.h> // will be llvm/IR  was llvm/Assembly

#include <clang/Frontend/ASTUnit.h>
#include <clang/AST/Comment.h>
#include <clang/AST/DeclTemplate.h>
#include <clang/AST/DeclFriend.h>
#include <clang/AST/DeclOpenMP.h>
#include <clang/AST/Stmt.h>
#include <clang/AST/StmtCXX.h>
#include <clang/AST/ExprObjC.h>
#include <clang/AST/StmtObjC.h>
#include <clang/AST/StmtOpenMP.h>

#include <clang/Basic/Version.h>
#include <clang/Tooling/JSONCompilationDatabase.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/AST/Comment.h>
#include <clang/Tooling/Tooling.h>
#include <clang/Tooling/Refactoring.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Frontend/FrontendActions.h>
#include <clang/AST/ASTConsumer.h>
#include <clang/AST/ASTContext.h>
#include <clang/Rewrite/Core/Rewriter.h>
#include <clang/Lex/Lexer.h>
#include <clang/Lex/Preprocessor.h>
#include <clang/ASTMatchers/Dynamic/VariantValue.h>
#include <clang/ASTMatchers/ASTMatchFinder.h>

#include <clasp/core/symbolTable.h>

#include <clasp/gctools/gctoolsPackage.h>
#include <clasp/core/metaClass.h>
#include <clasp/gctools/gcStack.h>
#include <clasp/gctools/containers.h>
#include <clasp/core/weakPointer.h>
#include <clasp/core/random.h>
#include <clasp/core/mpPackage.h>
#include <clasp/core/unixfsys.h>
#include <clasp/core/weakHashTable.h>
#include <clasp/core/smallMultimap.h>
//#include "core/symbolVector.h"
#include <clasp/core/designators.h>
#include <clasp/core/hashTable.h>
#include <clasp/core/hashTableEq.h>
#include <clasp/core/hashTableEql.h>
#include <clasp/core/hashTableEqual.h>
#include <clasp/core/hashTableEqualp.h>
#include <clasp/core/hashTableCustom.h>
#include <clasp/core/userData.h>
#include <clasp/core/loadTimeValues.h>
#include <clasp/core/specialForm.h>
#include <clasp/core/instance.h>
#include <clasp/core/funcallableInstance.h>
#include <clasp/core/singleDispatchGenericFunction.h>
#include <clasp/core/arguments.h>
#include <clasp/core/serialize.h>
#include <clasp/core/bootStrapCoreSymbolMap.h>
#include <clasp/core/corePackage.h>
#include <clasp/core/lambdaListHandler.h>
#include <clasp/core/package.h>
#include <clasp/core/character.h>
//#include <clasp/core/reader.h>
//#include <clasp/core/regex.h>
#include <clasp/core/array.h>
#include <clasp/core/readtable.h>
#include <clasp/core/nativeVector.h>
#include <clasp/core/lispStream.h>
#include <clasp/core/primitives.h>
#include <clasp/core/singleDispatchMethod.h>
#include <clasp/core/fileSystem.h>
#include <clasp/core/null.h>
#include <clasp/core/multiStringBuffer.h>
#include <clasp/core/posixTime.h>
#include <clasp/core/pointer.h>
#include <clasp/core/debugger.h> // Frame_O
#include <clasp/core/smallMap.h>
#include <clasp/core/pathname.h>
#include <clasp/core/sharpEqualWrapper.h>
#include <clasp/core/weakHashTable.h>
#include <clasp/core/intArray.h>
#include <clasp/core/fli.h>
#include <clasp/gctools/gc_boot.h>

#include <clasp/mpip/claspMpi.h>

#include <clasp/clbind/clbind.h>

#include <clasp/llvmo/intrinsics.h>
#include <clasp/llvmo/llvmoExpose.h>
#include <clasp/llvmo/debugLoc.h>
#include <clasp/llvmo/insertPoint.h>
#include <clasp/llvmo/debugInfoExpose.h>

#include <clasp/asttooling/astExpose.h>
#include <clasp/asttooling/clangTooling.h>
#include <clasp/asttooling/astVisitor.h>
#include <clasp/asttooling/example.h>
//#include <clasp/asttooling/Registry.h>
//#include <clasp/asttooling/Diagnostics.h>
//#include <clasp/asttooling/Marshallers.h>

#ifdef BUILD_EXTENSION
#define GC_INTERFACE_INCLUDES
#include <project_headers.h>
#undef GC_INTERFACE_INCLUDES
#endif

#define NAMESPACE_gctools
#define NAMESPACE_core
#include <clasp/gctools/gc_interface.h>
#undef NAMESPACE_gctools
#undef NAMESPACE_core

/*! Template types with commas in them can't be passed
to macros unless they are wrapped in this.
eg: offsetof(MACRO_SAFE_TYPE(a<b,c>),d)
*/
#define SAFE_TYPE_MACRO(...) __VA_ARGS__

#ifdef _TARGET_OS_DARWIN
// The OS X offsetof macro is defined as __offsetof which is defined as __builtin_offsetof - take out one level of macro so that the MACRO_SAFE_TYPE hack works
#undef offsetof
#define offsetof(t,x) __builtin_offsetof(t,x)
#endif

namespace gctools {

/* This is where the class_layout codes are included
from clasp_gc.cc
They are generated by the layout analyzer. */

Layout_code* get_stamp_layout_codes() {
  static Layout_code codes[] = {
#if defined(USE_MPS)
#ifndef RUNNING_MPSPREP
#define GC_OBJ_SCAN_HELPERS
#include CLASP_GC_FILENAME
#undef GC_OBJ_SCAN_HELPERS
#endif // #ifndef RUNNING_MPSPREP
#endif // #if defined(USE_MPS) || (defined(USE_BOEHM) && !defined(USE_CXX_DYNAMIC_CAST))
      {layout_end, 0, 0, 0, "" }
  };
  return &codes[0];
};
};

/* ----------------------------------------------------------------------
 *
 *  Expose functions
 *
 */

#define BAD_HEADER(msg,hdr) \
  printf("%s:%d Illegal header@%p in %s  header->header=%" PRIxPTR "  header->data[0]=%" PRIxPTR "  header->data[1]=%" PRIxPTR "\n", __FILE__, __LINE__, &hdr, msg, hdr.header._value, hdr.additional_data[0], hdr.additional_data[1]);

template <typename RT, typename...ARGS>
NOINLINE void expose_function(const std::string& pkg_sym,
                              RT (*fp)(ARGS...),
                              const std::string& lambdaList)
{
  std::string pkgName;
  std::string symbolName;
  core::colon_split(pkg_sym,pkgName,symbolName);
//  printf("%s:%d  expose_function   pkgName=%s  symbolName=%s\n", __FILE__, __LINE__, pkgName.c_str(), symbolName.c_str() );
  core::wrap_function(pkgName,symbolName,fp,lambdaList);
}

template <typename RT, typename...ARGS>
NOINLINE void expose_function_setf(const std::string& pkg_sym,
                                   RT (*fp)(ARGS...),
                                   const std::string& lambdaList)
{
  std::string pkgName;
  std::string symbolName;
  core::colon_split(pkg_sym,pkgName,symbolName);
  core::wrap_function_setf(pkgName,symbolName,fp,lambdaList);
}


#ifndef SCRAPING
  #define EXPOSE_FUNCTION_SIGNATURES
  #include INIT_FUNCTIONS_INC_H
  #undef EXPOSE_FUNCTION_SIGNATURES
#endif

#ifndef SCRAPING
  #define EXPOSE_FUNCTION_BINDINGS_HELPERS
  #undef EXPOSE_FUNCTION_BINDINGS
  #include INIT_FUNCTIONS_INC_H
  #undef EXPOSE_FUNCTION_BINDINGS_HELPERS
#endif

void initialize_functions()
{
//  printf("%s:%d About to initialize_functions\n", __FILE__, __LINE__ );
#ifndef SCRAPING
  #define EXPOSE_FUNCTION_BINDINGS
  #include INIT_FUNCTIONS_INC_H
  #undef EXPOSE_FUNCTION_BINDINGS
#endif
};


extern "C" {
using namespace gctools;

size_t obj_kind( core::T_O *tagged_ptr) {
  const core::T_O *client = untag_object<const core::T_O *>(tagged_ptr);
  const Header_s *header = reinterpret_cast<const Header_s *>(ClientPtrToBasePtr(client));
  return (size_t)(header->stamp_());
}

const char *obj_kind_name(core::T_O *tagged_ptr) {
  core::T_O *client = untag_object<core::T_O *>(tagged_ptr);
  const Header_s *header = reinterpret_cast<const Header_s *>(ClientPtrToBasePtr(client));
  return obj_name(header->stamp_());
}

bool valid_stamp(gctools::stamp_t stamp) {
#ifdef USE_MPS
  size_t stamp_index = (size_t)stamp;
  if (stamp_index<global_stamp_max) return true;
  return false;
#endif
#ifdef USE_BOEHM
  if (stamp<=global_unshifted_nowhere_stamp_names.size()) {
    return true;
  }
  return false;
#endif
}
const char *obj_name(gctools::stamp_t stamp) {
#ifdef USE_MPS
  if (stamp == (gctools::stamp_t)STAMP_null) {
    return "UNDEFINED";
  }
  if ( stamp > STAMP_max ) stamp = gctools::GCStamp<core::Instance_O>::Stamp;
  size_t stamp_index = (size_t)stamp;
  ASSERT(stamp_index<=global_stamp_max);
//  printf("%s:%d obj_name stamp= %d  stamp_index = %d\n", __FILE__, __LINE__, stamp, stamp_index);
  return global_stamp_info[stamp_index].name;
  #endif
#ifdef USE_BOEHM
  if (stamp<=global_unshifted_nowhere_stamp_names.size()) {
//    printf("%s:%d obj_name stamp= %lu\n", __FILE__, __LINE__, stamp);
    return global_unshifted_nowhere_stamp_names[stamp].c_str();
  }
  printf("%s:%d obj_name stamp = %lu is out of bounds - max is %lu\n", __FILE__, __LINE__, stamp, global_unshifted_nowhere_stamp_names.size());
  return NULL;
#endif
  
}

/*! I'm using a format_header so MPS gives me the object-pointer */
#define GC_DEALLOCATOR_METHOD
void obj_deallocate_unmanaged_instance(gctools::smart_ptr<core::T_O> obj ) {
  void* client = &*obj;
  printf("%s:%d About to obj_deallocate_unmanaged_instance %s\n", __FILE__, __LINE__, _rep_(obj).c_str() );
  // The client must have a valid header
#ifdef USE_MPS
  #ifndef RUNNING_MPSPREP
    #define GC_OBJ_DEALLOCATOR_TABLE
    #include CLASP_GC_FILENAME
    #undef GC_OBJ_DEALLOCATOR_TABLE
  #endif
#endif

  const gctools::Header_s *header = reinterpret_cast<const gctools::Header_s *>(ClientPtrToBasePtr(client));
  ASSERTF(header->stampP(), BF("obj_deallocate_unmanaged_instance called without a valid object"));
  gctools::GCStampEnum stamp = (GCStampEnum)(header->stamp_());
#ifndef RUNNING_MPSPREP
  #ifdef USE_MPS
  size_t jump_table_index = (size_t)stamp; // - stamp_first_general;
  printf("%s:%d Calculated jump_table_index %lu\n", __FILE__, __LINE__, jump_table_index);
  goto *(OBJ_DEALLOCATOR_table[jump_table_index]);
    #define GC_OBJ_DEALLOCATOR
    #include CLASP_GC_FILENAME
    #undef GC_OBJ_DEALLOCATOR
  #endif // USE_MPS
#endif
};
#undef GC_DEALLOCATOR_METHOD

};


// ----------------------------------------------------------------------
//
// Declare all global symbols
//
//


#define DECLARE_ALL_SYMBOLS
#ifndef SCRAPING
#include SYMBOLS_SCRAPED_INC_H
#endif
#undef DECLARE_ALL_SYMBOLS




#ifdef USE_MPS
extern "C" {
  using namespace gctools;
  /*! I'm using a format_header so MPS gives me the object-pointer */
  mps_addr_t obj_skip_debug(mps_addr_t client,bool dbg) {
    mps_addr_t oldClient = client;
    size_t size = 0;
    const gctools::Header_s* header_ptr = reinterpret_cast<const gctools::Header_s *>(ClientPtrToBasePtr(client));
    const gctools::Header_s& header = *header_ptr;
    const Header_s::StampWtagMtag& header_value = header._stamp_wtag_mtag;
    tagged_stamp_t mtag = header_value.mtag();
#ifdef DEBUG_ON
    if (dbg) {
      LOG(BF("obj_scan_debug mtag = %d  AlignUp(size + sizeof(Header_s)) -> %lu + header.tail_size())-> %lu\n")
          % mtag % (AlignUp(size + sizeof(Header_s))) % header.tail_size() );
    }
#endif
    switch (mtag) {
    case gctools::Header_s::stamp_tag: {
#ifdef DEBUG_VALIDATE_GUARD
      header->validate();
#endif
      gctools::GCStampEnum stamp_wtag = header.stamp_wtag();
      size_t stamp_index = header.stamp_();
#ifdef DEBUG_ON
      if (dbg) {
        LOG(BF("stamp_wtag = %lu stamp_index=%lu\n") % (size_t)stamp_wtag % stamp_index);
      }
#endif
      if ( stamp_wtag == STAMP_core__DerivableCxxObject_O ) {
#ifdef DEBUG_ON
        if (dbg) {
          LOG(BF("DerivableCxxObject\n"));
        }
#endif
        // If this is true then I think we need to call virtual functions on the client
        // to determine the Instance_O offset and the total size of the object.
        printf("%s:%d Handle STAMP_core__DerivableCxxObject_O\n", __FILE__, __LINE__ );
      }
      const Stamp_layout& stamp_layout = global_stamp_layout[stamp_index];
      unlikely_if ( stamp_wtag == STAMP_core__SimpleBitVector_O ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("SimpleBitVector\n"));}
#endif
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
        size = core::SimpleBitVector_O::bitunit_array_type::sizeof_for_length(capacity) + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
        // Do other bitunit vectors here
      }
      unlikely_if ( stamp_wtag == STAMP_core__SimpleVector_byte2_t_O ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("STAMP_core__SimpleVector_byte2_t_O"));}
#endif
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
        size = core::SimpleVector_byte2_t_O::bitunit_array_type::sizeof_for_length(capacity) + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
      }
      unlikely_if ( stamp_wtag == STAMP_core__SimpleVector_int2_t_O ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("STAMP_core__SimpleVector_int2_t_O"));}
#endif
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
        size = core::SimpleVector_int2_t_O::bitunit_array_type::sizeof_for_length(capacity) + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
      }
      unlikely_if ( stamp_wtag == STAMP_core__SimpleVector_byte4_t_O ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("STAMP_core__SimpleVector_byte4_t_O"));}
#endif
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
        size = core::SimpleVector_byte4_t_O::bitunit_array_type::sizeof_for_length(capacity) + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
      }
      unlikely_if ( stamp_wtag == STAMP_core__SimpleVector_int4_t_O ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("STAMP_core__SimpleVector_int4_t_O"));}
#endif
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
        size = core::SimpleVector_int4_t_O::bitunit_array_type::sizeof_for_length(capacity) + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
      }
      unlikely_if (stamp_wtag == gctools::STAMP_core__SimpleBaseString_O) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("SimpleBaseString\n"));}
#endif
        // Account for the SimpleBaseString additional byte for \0
        size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset) + 1;
        size = stamp_layout.element_size*capacity + stamp_layout.data_offset;
        goto STAMP_CONTINUE;
      }
      if ( stamp_layout.container_layout ) {
#ifdef DEBUG_ON
        if (dbg) {LOG(BF("container_layout\n"));}
#endif
        // special cases
        Container_layout& container_layout = *stamp_layout.container_layout;
        // For bignums we allow the _MaybeSignedLength(capacity) to be a negative value to represent negative bignums
        // because GMP only stores positive bignums.  So the value at stamp_layout.capacity_offset is a signed int64_t
        // Because of this we need to take the absolute value to get the number of entries.
        size_t capacity = (size_t)std::llabs(*(int64_t*)((const char*)client + stamp_layout.capacity_offset));
        size = stamp_layout.element_size*capacity + stamp_layout.data_offset;
      } else {
        if (stamp_layout.layout_op == templated_op) {
#ifdef DEBUG_ON
          if (dbg) {LOG(BF("templatedSizeof\n"));}
#endif
          size = ((core::General_O*)client)->templatedSizeof();
        } else {
#ifdef DEBUG_ON
          if (dbg) {LOG(BF("stamp_layout.size = %lu\n") % stamp_layout.size);}
#endif
          size = stamp_layout.size;
        }
      }
      STAMP_CONTINUE:
      client = (mps_addr_t)((char*)client + AlignUp(size + sizeof(Header_s)) + header.tail_size());
      break;
    }
    case gctools::Header_s::fwd_tag: {
      client = (char *)(client) + header.fwdSize();
      break;
    }
    case gctools::Header_s::pad_tag: {
      if (header_value.pad1P()) {
        client = (char *)(client) + header.pad1Size();
      } else {
        client = (char *)(client) + header.padSize();
      }
      break;
    }
    case gctools::Header_s::invalid_tag: {
      throw_hard_error_bad_client((void*)client);
    }
    }
    return client;
  }

  mps_addr_t obj_skip(mps_addr_t client) {
    return obj_skip_debug(client,false);
  }

  __attribute__((noinline))  mps_addr_t obj_skip_debug_wrong_size(mps_addr_t client,
                                                                  void* header,
                                                                  size_t stamp_wtag_mtag,
                                                                  size_t stamp,
                                                                  size_t allocate_size,
                                                                  size_t skip_size,
                                                                  int delta) {
    printf("%s:%d Bad size calc header@%p header->stamp_wtag_mtag._value(%lu) obj_skip(stamp %lu) allocate_size -> %lu  obj_skip -> %lu delta -> %d\n         About to recalculate the size - connect a debugger and break on obj_skip_debug_wrong_size to trap\n",
           __FILE__, __LINE__, (void*)header, stamp_wtag_mtag, stamp, allocate_size, skip_size, delta );
    return obj_skip_debug(client,true);
  }


};
#endif // ifdef USE_MPS


#ifdef USE_MPS

struct ValidateObjects {};

template <typename Op>
inline void operate(core::T_O** ptr) {
  printf("%s:%d Illegal operate\n", __FILE__, __LINE__ );
}

template <>
inline void operate<ValidateObjects>(core::T_O** ptr)
{
  printf("%s:%d Validate the pointer at %p\n", __FILE__, __LINE__, ptr);
}

// ------------------------------------------------------------
//
// The following MUST match the code in obj_scan
//
template <typename Op>
inline mps_addr_t general_object_pointer_walk(mps_addr_t client)
{
  size_t size;
  mps_addr_t oldClient = client;
  const gctools::Header_s& header = *reinterpret_cast<const gctools::Header_s *>(ClientPtrToBasePtr(client));
  const Header_s::StampWtagMtag& header_value = header._stamp_wtag_mtag;
  size_t stamp_index = header.stamp_();
#ifdef DEBUG_VALIDATE_GUARD
  header->validate();
#endif
  gctools::GCStampEnum stamp_wtag = header.stamp_wtag();
  const Stamp_layout& stamp_layout = global_stamp_layout[stamp_index];
  if ( stamp_wtag == STAMP_core__DerivableCxxObject_O ) {
    // If this is true then I think we need to call virtual functions on the client
    // to determine the Instance_O offset and the total size of the object.
    printf("%s:%d Handle STAMP_core__DerivableCxxObject_O\n", __FILE__, __LINE__ );
  }
  if (stamp_layout.layout_op == templated_op ) {
    size = ((core::General_O*)client)->templatedSizeof();
  } else {
    size = stamp_layout.size;
  }
  if ( stamp_layout.field_layout_start ) {
    int num_fields = stamp_layout.number_of_fields;
    const Field_layout* field_layout_cur = stamp_layout.field_layout_start;
    for ( int i=0; i<num_fields; ++i ) {
      core::T_O** field = (core::T_O**)((const char*)client + field_layout_cur->field_offset);
      operate<Op>(field);
      ++field_layout_cur;
    }
  }
  if ( stamp_layout.container_layout ) {
    const Container_layout& container_layout = *stamp_layout.container_layout;
    // For bignums we allow the _MaybeSignedLength(capacity) to be a negative value to represent negative bignums
    // because GMP only stores positive bignums.  So the value at stamp_layout.capacity_offset is a signed int64_t
    // Because of this we need to take the absolute value to get the number of entries so that we can calculate the
    // size of this object properly. We also need to do this in obj_skip
    size_t capacity = (size_t)std::llabs(*(int64_t*)((const char*)client + stamp_layout.capacity_offset));
    size = stamp_layout.element_size*capacity + stamp_layout.data_offset;
    size_t end = capacity;
    if (stamp_layout.end_offset!=stamp_layout.capacity_offset) {
      // This is a GCVector_moveable and it has an extra 'end' slot that represents the actual number of
      // values that we need to scan.  end <= capacity
      size_t end = *(size_t*)((const char*)client + stamp_layout.end_offset);
    }
    for ( int i=0; i<end; ++i ) {
      Field_layout* field_layout_cur = container_layout.field_layout_start;
      ASSERT(field_layout_cur);
      const char* element = ((const char*)client + stamp_layout.data_offset + stamp_layout.element_size*i);
      for ( int j=0; j<container_layout.number_of_fields; ++j ) {
        core::T_O** field = (core::T_O**)((const char*)element + field_layout_cur->field_offset);
        operate<Op>(field);
        ++field_layout_cur;
      }
    }
  }
  client = (mps_addr_t)((char*)client + AlignUp(size + sizeof(Header_s)) + header.tail_size());
#ifdef DEBUG_MPS_SIZE
  {
    size_t scan_size = ((char*)client-(char*)oldClient);
    size_t skip_size = ((char*)obj_skip(oldClient)-(char*)oldClient);
    if (scan_size != skip_size) {
      printf("%s:%d The size of the object with stamp %u will not be calculated properly - obj_scan -> %lu  obj_skip -> %lu\n",
             __FILE__, __LINE__, header.stamp_(), scan_size, skip_size);
    }
  }
#endif
  return client;
}

extern "C" {
#define SCAN_STRUCT_T mps_ss_t
#define ADDR_T mps_addr_t
#define SCAN_BEGIN(xxx) MPS_SCAN_BEGIN(xxx)
#define SCAN_END(xxx) MPS_SCAN_END(xxx)
#define OBJECT_SCAN obj_scan
#define GC_OBJECT_SCAN
#include "obj_scan.cc"
#undef GC_OBJ_SCAN
#undef OBJ_SCAN
#undef SCAN_STRUCT_T

#if 0
GC_RESULT obj_scan(mps_ss_t ss, mps_addr_t client, mps_addr_t limit) {
  LOG(BF("obj_scan START client=%p limit=%p\n") % (void*)client % (void*)limit );
  mps_addr_t oldClient;
  size_t stamp_index;
  size_t size;
  MPS_SCAN_BEGIN(GC_SCAN_STATE) {
    while (client < limit) {
      oldClient = (mps_addr_t)client;
      // The client must have a valid header
      const gctools::Header_s& header = *reinterpret_cast<const gctools::Header_s *>(ClientPtrToBasePtr(client));
      const Header_s::StampWtagMtag& header_value = header._stamp_wtag_mtag;
      stamp_index = header.stamp_();
      LOG(BF("obj_scan client=%p stamp=%lu\n") % (void*)client % stamp_index );
      tagged_stamp_t mtag = header_value.mtag();
      switch (mtag) {
      case gctools::Header_s::stamp_tag: {
#ifdef DEBUG_VALIDATE_GUARD
        header->validate();
#endif
        gctools::GCStampEnum stamp_wtag = header.stamp_wtag();
        const Stamp_layout& stamp_layout = global_stamp_layout[stamp_index];
        if ( stamp_wtag == STAMP_core__DerivableCxxObject_O ) {
        // If this is true then I think we need to call virtual functions on the client
        // to determine the Instance_O offset and the total size of the object.
          printf("%s:%d Handle STAMP_core__DerivableCxxObject_O\n", __FILE__, __LINE__ );
        }
        if (stamp_layout.layout_op == templated_op ) {
          size = ((core::General_O*)client)->templatedSizeof();
        } else {
          size = stamp_layout.size;
        }
        if ( stamp_layout.field_layout_start ) {
          int num_fields = stamp_layout.number_of_fields;
          const Field_layout* field_layout_cur = stamp_layout.field_layout_start;
          for ( int i=0; i<num_fields; ++i ) {
            core::T_O** field = (core::T_O**)((const char*)client + field_layout_cur->field_offset);
            POINTER_FIX(field);
            ++field_layout_cur;
          }
        }
        if ( stamp_layout.container_layout ) {
          const Container_layout& container_layout = *stamp_layout.container_layout;
          size_t capacity = *(size_t*)((const char*)client + stamp_layout.capacity_offset);
          size = stamp_layout.element_size*capacity + stamp_layout.data_offset;
          size_t end = *(size_t*)((const char*)client + stamp_layout.end_offset);
          for ( int i=0; i<end; ++i ) {
            Field_layout* field_layout_cur = container_layout.field_layout_start;
            ASSERT(field_layout_cur);
            const char* element = ((const char*)client + stamp_layout.data_offset + stamp_layout.element_size*i);
            for ( int j=0; j<container_layout.number_of_fields; ++j ) {
              core::T_O** field = (core::T_O**)((const char*)element + field_layout_cur->field_offset);
              POINTER_FIX(field);
              ++field_layout_cur;
            }
          }
        }
        client = (mps_addr_t)((char*)client + AlignUp(size + sizeof(Header_s)) + header.tail_size());
#ifdef DEBUG_MPS_SIZE
        {
          size_t scan_size = ((char*)client-(char*)oldClient);
          size_t skip_size = ((char*)obj_skip(oldClient)-(char*)oldClient);
          if (scan_size != skip_size) {
            printf("%s:%d The size of the object with stamp %u will not be calculated properly - obj_scan -> %lu  obj_skip -> %lu\n",
                   __FILE__, __LINE__, header.stamp_(), scan_size, skip_size);
          }
        }
#endif
        break;
      }
      case gctools::Header_s::fwd_tag: {
        client = (char *)(client) + header.fwdSize();
#ifdef DEBUG_MPS_SIZE
        {
          size_t scan_size = ((char*)client-(char*)oldClient);
          size_t skip_size = ((char*)obj_skip(oldClient)-(char*)oldClient);
          if (scan_size != skip_size) {
            printf("%s:%d The size of the object with fwd_tag will not be calculated properly - obj_scan -> %lu  obj_skip -> %lu\n",
                   __FILE__, __LINE__, scan_size, skip_size);
          }
        }
#endif
        break;
      }
      case gctools::Header_s::pad_tag: {
        if (header_value.pad1P()) {
          client = (char *)(client) + header.pad1Size();
        } else if (header.padP()) {
          client = (char *)(client) + header.padSize();
        }
#ifdef DEBUG_MPS_SIZE
        {
          size_t scan_size = ((char*)client-(char*)oldClient);
          size_t skip_size = ((char*)obj_skip(oldClient)-(char*)oldClient);
          if (scan_size != skip_size) {
            printf("%s:%d The size of the object with pad_tag will not be calculated properly - obj_scan -> %lu  obj_skip -> %lu\n",
                   __FILE__, __LINE__, scan_size, skip_size);
          }
        }
#endif
        break;
      }
      case gctools::Header_s::invalid_tag: {
        throw_hard_error_bad_client((void*)client);
      }
      }
    }
  } MPS_SCAN_END(GC_SCAN_STATE);
  LOG(BF("obj_scan ENDING client=%p\n") % (void*)client );
  return MPS_RES_OK;
}
#endif
};
#endif // ifdef USE_MPS


#ifdef USE_MPS
extern "C" {
/*! I'm using a format_header so MPS gives me the object-pointer */
  #define GC_FINALIZE_METHOD
void obj_finalize(mps_addr_t client) {
  // The client must have a valid header
  DEBUG_THROW_IF_INVALID_CLIENT(client);
  mps_addr_t next_client = obj_skip(client);
  size_t block_size = (char*)next_client-(char*)client;
  #ifndef RUNNING_MPSPREP
    #define GC_OBJ_FINALIZE_TABLE
    #include CLASP_GC_FILENAME
    #undef GC_OBJ_FINALIZE_TABLE
  #endif // ifndef RUNNING_MPSPREP
  gctools::Header_s *header = reinterpret_cast<gctools::Header_s *>(const_cast<void*>(ClientPtrToBasePtr(client)));
  ASSERTF(header->stampP(), BF("obj_finalized called without a valid object"));
  gctools::GCStampEnum stamp = (GCStampEnum)(header->stamp_());
  #ifndef RUNNING_MPSPREP
  size_t table_index = (size_t)stamp;
  goto *(OBJ_FINALIZE_table[table_index]);
    #define GC_OBJ_FINALIZE
    #include CLASP_GC_FILENAME
    #undef GC_OBJ_FINALIZE
  #endif // ifndef RUNNING_MPSPREP
 finalize_done:
  // Now replace the object with a pad object
  header->setPadSize(block_size);
  header->setPad(Header_s::pad_tag);
}; // obj_finalize
}; // extern "C"
  #undef GC_FINALIZE_METHOD
#endif // ifdef USE_MPS



#ifdef USE_MPS
extern "C" {
mps_res_t main_thread_roots_scan(mps_ss_t ss, void *gc__p, size_t gc__s) {
  MPS_SCAN_BEGIN(GC_SCAN_STATE) {
#ifndef RUNNING_MPSPREP
#define GC_GLOBALS
#include CLASP_GC_FILENAME
#undef GC_GLOBALS
#endif
    for ( int i=0; i<global_symbol_count; ++i ) {
      SMART_PTR_FIX(global_symbols[i]);
    }
  }
  MPS_SCAN_END(GC_SCAN_STATE);
  return MPS_RES_OK;
}
};
#endif // USE_MPS

//
// We don't want the static analyzer gc-builder.lsp to see the generated scanners
//
#ifdef USE_MPS
  #ifndef RUNNING_MPSPREP
    #ifndef SCRAPING
      #define HOUSEKEEPING_SCANNERS
      #include CLASP_GC_FILENAME
      #undef HOUSEKEEPING_SCANNERS
    #endif // ifdef USE_MPS
  #endif // ifndef RUNNING_MPSPREP
#endif // ifdef USE_MPS

//
// Bootstrapping
//

void setup_bootstrap_packages(core::BootStrapCoreSymbolMap* bootStrapSymbolMap)
{
  #define BOOTSTRAP_PACKAGES
  #ifndef SCRAPING
    #include SYMBOLS_SCRAPED_INC_H
  #endif
  #undef BOOTSTRAP_PACKAGES
}

template <class TheClass>
void set_one_static_class_symbol(core::BootStrapCoreSymbolMap* symbols, const std::string& full_name )
{
  std::string orig_package_part, orig_symbol_part;
  core::colon_split( full_name, orig_package_part, orig_symbol_part);
  std::string package_part, symbol_part;
  package_part = core::lispify_symbol_name(orig_package_part);
  symbol_part = core::lispify_symbol_name(orig_symbol_part);
//  printf("%s:%d set_one_static_class_symbol --> %s:%s\n", __FILE__, __LINE__, package_part.c_str(), symbol_part.c_str() );
  core::SymbolStorage store;
  bool found =  symbols->find_symbol(package_part,symbol_part, store );
  if ( !found ) {
    printf("%s:%d ERROR!!!! The static class symbol %s was not found orig_symbol_part=|%s| symbol_part=|%s|!\n", __FILE__, __LINE__, full_name.c_str(), orig_symbol_part.c_str(), symbol_part.c_str() );
    abort();
  }
  if (store._PackageName != package_part) {
    printf("%s:%d For symbol %s there is a mismatch in the package desired %s and the one retrieved %s\n", __FILE__, __LINE__, full_name.c_str(), package_part.c_str(), store._PackageName.c_str());
    SIMPLE_ERROR(BF("Mismatch of package when setting a class symbol"));
  }
//  printf("%s:%d Setting static_class_symbol to %s\n", __FILE__, __LINE__, _safe_rep_(store._Symbol).c_str());
  TheClass::set_static_class_symbol(store._Symbol);
}

void set_static_class_symbols(core::BootStrapCoreSymbolMap* bootStrapSymbolMap)
{
#define SET_CLASS_SYMBOLS
#ifndef SCRAPING
#include INIT_CLASSES_INC_H
#endif
#undef SET_CLASS_SYMBOLS
}

#define ALLOCATE_ALL_SYMBOLS_HELPERS
#undef ALLOCATE_ALL_SYMBOLS
#ifndef SCRAPING
#include SYMBOLS_SCRAPED_INC_H
#endif
#undef ALLOCATE_ALL_SYMBOLS_HELPERS

void allocate_symbols(core::BootStrapCoreSymbolMap* symbols)
{
#define ALLOCATE_ALL_SYMBOLS
  #ifndef SCRAPING
    #include SYMBOLS_SCRAPED_INC_H
  #endif
#undef ALLOCATE_ALL_SYMBOLS
};

template <class TheClass>
NOINLINE void set_one_static_class_Header() {
  ShiftedStamp the_stamp = gctools::NextStampWtag(0 /* Get from the Stamp */,gctools::GCStamp<TheClass>::Stamp);
  if (gctools::GCStamp<TheClass>::Stamp!=0) {
    TheClass::static_StampWtagMtag = gctools::Header_s::StampWtagMtag::make<TheClass>();
  } else {
#ifdef USE_MPS
    if (core::global_initialize_builtin_classes) {
      printf("!\n!\n! %s:%d While initializing builtin classes with MPS clasp\n!\n!\n! A class was found without a Stamp - this happens if you haven't run the static analyzer since adding a class\n! Go run the static analyzer.\n!\n!\n!\n", __FILE__, __LINE__ );
      abort();
    }
#endif
    TheClass::static_StampWtagMtag = gctools::Header_s::StampWtagMtag::make_unknown(the_stamp);
  }
}


template <class TheClass>
NOINLINE  gc::smart_ptr<core::Instance_O> allocate_one_metaclass(UnshiftedStamp theStamp, core::Symbol_sp classSymbol, core::Instance_sp metaClass)
{
  core::FunctionDescription* fdesc = core::makeFunctionDescription(kw::_sym_create);
  auto cb = gctools::GC<TheClass>::allocate(fdesc);
  gc::smart_ptr<core::Instance_O> class_val = core::Instance_O::createClassUncollectable(theStamp,metaClass,REF_CLASS_NUMBER_OF_SLOTS_IN_STANDARD_CLASS,cb);
  class_val->__setup_stage1_with_sharedPtr_lisp_sid(class_val,classSymbol);
//  reg::lisp_associateClassIdWithClassSymbol(reg::registered_class<TheClass>::id,TheClass::static_classSymbol());
//  TheClass::static_class = class_val;
  _lisp->boot_setf_findClass(classSymbol,class_val);
//  core::core__setf_find_class(class_val,classSymbol);
  return class_val;
}


template <class TheClass>
NOINLINE  gc::smart_ptr<core::Instance_O> allocate_one_class(core::Instance_sp metaClass)
{
  core::Creator_sp cb = gc::As<core::Creator_sp>(gctools::GC<core::BuiltInObjectCreator<TheClass>>::allocate());
  TheClass::set_static_creator(cb);
  gc::smart_ptr<core::Instance_O> class_val = core::Instance_O::createClassUncollectable(TheClass::static_StampWtagMtag.shifted_stamp(),metaClass,REF_CLASS_NUMBER_OF_SLOTS_IN_STANDARD_CLASS,cb);
  class_val->__setup_stage1_with_sharedPtr_lisp_sid(class_val,TheClass::static_classSymbol());
  reg::lisp_associateClassIdWithClassSymbol(reg::registered_class<TheClass>::id,TheClass::static_classSymbol());
  TheClass::setStaticClass(class_val);
//  core::core__setf_find_class(class_val,TheClass::static_classSymbol()); //,true,_Nil<core::T_O>()
  _lisp->boot_setf_findClass(TheClass::static_classSymbol(),class_val);
  return class_val;
}

template <class TheMetaClass>
struct TempClass {
  static gctools::smart_ptr<TheMetaClass> holder;
};


std::map<std::string,size_t> global_unshifted_nowhere_stamp_name_map;
std::vector<std::string> global_unshifted_nowhere_stamp_names;
// Keep track of the where information given an unshifted_nowhere_stamp
std::vector<size_t> global_unshifted_nowhere_stamp_where_map;
size_t _global_last_stamp = 0;

//#define DUMP_NAMES 1

void register_stamp_name(const std::string& stamp_name, UnshiftedStamp unshifted_stamp) {
  if (unshifted_stamp==0) return;
  size_t stamp_where = gctools::Header_s::StampWtagMtag::get_stamp_where(unshifted_stamp);
  size_t stamp_num = gctools::Header_s::StampWtagMtag::make_nowhere_stamp(unshifted_stamp);
#ifdef DUMP_NAMES
  printf("%s:%d  stamp_num=%u  name=%s\n", __FILE__, __LINE__, stamp_num,stamp_name.c_str());
#endif
  global_unshifted_nowhere_stamp_name_map[stamp_name] = stamp_num;
  if (stamp_num>=global_unshifted_nowhere_stamp_names.size()) {
    global_unshifted_nowhere_stamp_names.resize(stamp_num+1,"");
  }
  global_unshifted_nowhere_stamp_names[stamp_num] = stamp_name;
  if (stamp_num>=global_unshifted_nowhere_stamp_where_map.size()) {
    global_unshifted_nowhere_stamp_where_map.resize(stamp_num+1,0);
  }
  global_unshifted_nowhere_stamp_where_map[stamp_num] = stamp_where;
}

void define_builtin_cxx_classes() {
#ifndef SCRAPING
 #define GC_ENUM_NAMES
  #ifdef USE_BOEHM
   #include INIT_CLASSES_INC_H
  #endif
  #ifdef USE_MPS
   #include CLASP_GC_FILENAME
  #endif
 #undef GC_ENUM_NAMES
#endif
}


void create_packages()
{
  #define CREATE_ALL_PACKAGES
  #ifndef SCRAPING
    #include SYMBOLS_SCRAPED_INC_H
  #endif
  #undef CREATE_ALL_PACKAGES
}


void define_base_classes()
{
  IMPLEMENT_MEF("define_base_classes");
}


void calculate_class_precedence_lists()
{
  IMPLEMENT_MEF("calculate_class_precendence_lists");
}

// ------------------------------------------------------------
//
// Generate type specifier -> header value (range) map
//

template <typename TSingle>
void add_single_typeq_test(const string& cname, core::HashTable_sp theMap) {
  Fixnum header_val = gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TSingle>();
//  printf("%s:%d Header value for type %s -> %lld    stamp: %u  flags: %zu\n", __FILE__, __LINE__, _rep_(TSingle::static_class_symbol).c_str(), header_val, gctools::GCStamp<TSingle>::Stamp, gctools::GCStamp<TSingle>::Flags);
  theMap->setf_gethash(TSingle::static_classSymbol(),core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TSingle>()));
}

template <typename TRangeFirst,typename TRangeLast>
void add_range_typeq_test(const string& cname, core::HashTable_sp theMap) {
  
  theMap->setf_gethash(TRangeFirst::static_classSymbol(),
                       core::Cons_O::create(core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TRangeFirst>()),
                                            core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TRangeLast>())));
}
template <typename TSingle>
void add_single_typeq_test_instance(core::HashTable_sp theMap) {
  theMap->setf_gethash(TSingle::static_classSymbol(),core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TSingle>()));
}

template <typename TRangeFirst,typename TRangeLast>
void add_range_typeq_test_instance(core::HashTable_sp theMap) {
  theMap->setf_gethash(TRangeFirst::static_classSymbol(),
                       core::Cons_O::create(core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TRangeFirst>()),
                                            core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<TRangeLast>())));
}
  
void initialize_typeq_map() {
  core::HashTableEqual_sp classNameToLispName = core::HashTableEqual_O::create_default();
  core::HashTableEq_sp theTypeqMap = core::HashTableEq_O::create_default();
#define ADD_SINGLE_TYPEQ_TEST(type,stamp) { \
    classNameToLispName->setf_gethash(core::SimpleBaseString_O::make(#type),type::static_classSymbol()); \
    theTypeqMap->setf_gethash(type::static_classSymbol(),core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type>())); \
  }
#define ADD_RANGE_TYPEQ_TEST(type_low,type_high,stamp_low,stamp_high) { \
    classNameToLispName->setf_gethash(core::SimpleBaseString_O::make(#type_low),type_low::static_classSymbol()); \
    theTypeqMap->setf_gethash(type_low::static_classSymbol(), \
                              core::Cons_O::create(core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type_low>()), \
                                                   core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type_high>()))); \
  }
#define ADD_SINGLE_TYPEQ_TEST_INSTANCE(type,stamp) { \
    classNameToLispName->setf_gethash(core::SimpleBaseString_O::make(#type),type::static_classSymbol()); \
    theTypeqMap->setf_gethash(type::static_classSymbol(),core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type>())); \
  }
#define ADD_RANGE_TYPEQ_TEST_INSTANCE(type_low,type_high,stamp_low,stamp_high) { \
    classNameToLispName->setf_gethash(core::SimpleBaseString_O::make(#type_low),type_low::static_classSymbol()); \
    theTypeqMap->setf_gethash(type_low::static_classSymbol(), \
                              core::Cons_O::create(core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type_low>()), \
                                                   core::make_fixnum(gctools::Header_s::StampWtagMtag::GenerateHeaderValue<type_high>()))); \
  }
#ifndef SCRAPING
 #ifdef USE_BOEHM
  #define GC_TYPEQ
    #include INIT_CLASSES_INC_H // REPLACED CLASP_GC_FILENAME
  #undef GC_TYPEQ
 #endif
 #if defined(USE_MPS) && !defined(RUNNING_MPSPREP)
  #define GC_TYPEQ
   #include CLASP_GC_FILENAME
  #undef GC_TYPEQ
 #endif
#endif
  core::_sym__PLUS_class_name_to_lisp_name_PLUS_->defparameter(classNameToLispName);
  core::_sym__PLUS_type_header_value_map_PLUS_->defparameter(theTypeqMap);
};

// ----------------------------------------------------------------------
//
// Expose classes and methods
//
// Code generated by scraper
//
//
#include <clasp/core/wrappers.h>
#include <clasp/core/external_wrappers.h>

#ifndef SCRAPING
 #define EXPOSE_STATIC_CLASS_VARIABLES
  #include INIT_CLASSES_INC_H
 #undef EXPOSE_STATIC_CLASS_VARIABLES
#endif

#ifndef SCRAPING
 #define EXPOSE_METHODS
  #include INIT_CLASSES_INC_H
 #undef EXPOSE_METHODS
#endif

void initialize_enums()
{
  #define ALL_ENUMS
  #ifndef SCRAPING
    #include <generated/enum_inc.h>
  #endif
  #undef ALL_ENUMS
};


void initialize_classes_and_methods()
{
#ifndef SCRAPING
 #define EXPOSE_CLASSES_AND_METHODS
  #include INIT_CLASSES_INC_H
 #undef EXPOSE_CLASSES_AND_METHODS
#endif
}

#if 0
#define MPS_LOG(x) printf("%s:%d %s\n", __FILE__, __LINE__, x);
#else
#define MPS_LOG(x)
#endif

void initialize_clasp_Kinds()
{
  #ifndef SCRAPING
   #define SET_CLASS_KINDS
    #include INIT_CLASSES_INC_H
   #undef SET_CLASS_KINDS
  #endif
}

void dumpBoehmLayoutTables(FILE* fout) {
#define Init_class_kind(_class_) \
  fprintf(fout, "Init_class_kind( stamp=%lu, name=\"%s\", size=%lu)\n", _class_::static_StampWtagMtag.nowhere_stamp(),#_class_,sizeof(*(_class_*)0x0));
#define Init_templated_kind(_class_) \
  fprintf(fout, "Init_templated_kind( stamp=%lu, name=\"%s\", size=%lu)\n", _class_::static_StampWtagMtag.nowhere_stamp(),#_class_,sizeof(*(_class_*)0x0));
#define Init__fixed_field(_class_,_index_,_type_,_field_name_) \
  fprintf(fout, "Init__fixed_field( stamp=%lu, index=%d, data_type=%d,field_name=\"%s\",field_offset=%lu);\n", _class_::static_StampWtagMtag.nowhere_stamp(),_index_,_type_,#_field_name_,offsetof(_class_,_field_name_));
#define Init__variable_array0(_class_,_data_field_) \
  fprintf(fout,"Init__variable_array0( stamp=%lu, name=\"%s\", offset=%lu );\n", _class_::static_StampWtagMtag.nowhere_stamp(),#_data_field_,offsetof(_class_,_data_field_));
#define Init__variable_capacity(_class_,_value_type_,_end_,_capacity_) \
  fprintf(fout,"Init__variable_capacity( stamp=%lu, element_size=%lu, end_offset=%lu, capacity_offset=%lu );\n", _class_::static_StampWtagMtag.nowhere_stamp(),sizeof(_class_::_value_type_),offsetof(_class_,_end_),offsetof(_class_,_capacity_));
#define Init__variable_field(_class_,_data_type_,_index_,_field_name_,_field_offset_) \
  fprintf(fout,"Init__variable_field( stamp=%lu, index=%d, data_type=%d, field_name=\"%s\", field_offset=%d );\n", _class_::static_StampWtagMtag.nowhere_stamp(),_index_,_data_type_,_field_name_,_field_offset_);

  #if 0
  fprintf(fout, "Init_data_type( data_type=1, name=\"tagged_ptr\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=2, name=\"array\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=3, name=\"pointer\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=4, name=\"constant_array\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=5, name=\"double\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=6, name=\"float\",sizeof=4)\n");
  fprintf(fout, "Init_data_type( data_type=7, name=\"int\",sizeof=4)\n");
  fprintf(fout, "Init_data_type( data_type=8, name=\"short\",sizeof=2)\n");
  fprintf(fout, "Init_data_type( data_type=10, name=\"signed_char\",sizeof=1)\n");
  fprintf(fout, "Init_data_type( data_type=11, name=\"unsigned_short\",sizeof=2)\n");
  fprintf(fout, "Init_data_type( data_type=12, name=\"signed_short\",sizeof=2)\n");
  fprintf(fout, "Init_data_type( data_type=13, name=\"unsigned_long\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=14, name=\"unsigned_int\",sizeof=4)\n");
  fprintf(fout, "Init_data_type( data_type=15, name=\"long\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=16, name=\"long_long\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=17, name=\"char\",sizeof=1)\n");
  fprintf(fout, "Init_data_type( data_type=18, name=\"_Bool\",sizeof=1)\n");
  fprintf(fout, "Init_data_type( data_type=19, name=\"enum_core__StreamMode\",sizeof=4)\n");
  fprintf(fout, "Init_data_type( data_type=21, name=\"const_char_ptr\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=22, name=\"size_t\",sizeof=8)\n");
  fprintf(fout, "Init_data_type( data_type=23, name=\"opaque_ptr\",sizeof=8)\n");
#endif

  gctools::dump_data_types(fout,"");
  
  Init_class_kind(core::T_O);
  Init_class_kind(core::General_O);
  Init_class_kind(core::Cons_O);
  Init__fixed_field(core::Cons_O,0,SMART_PTR_OFFSET,_Car);
  Init__fixed_field(core::Cons_O,1,SMART_PTR_OFFSET,_Cdr);
  Init_class_kind(core::SimpleBaseString_O);
  Init__variable_array0(core::SimpleBaseString_O,_Data._Data);
  Init__variable_capacity(core::SimpleBaseString_O,value_type,_Data._MaybeSignedLength,_Data._MaybeSignedLength);
  Init__variable_field(core::SimpleBaseString_O,gctools::ctype_unsigned_char, 0, "only", 0);

  Init_class_kind(core::Function_O);
  
  Init_class_kind(core::Symbol_O);
  Init__fixed_field(core::Symbol_O,0,SMART_PTR_OFFSET,_Name);
  Init__fixed_field(core::Symbol_O,1,SMART_PTR_OFFSET,_HomePackage);
  Init__fixed_field(core::Symbol_O,2,SMART_PTR_OFFSET,_GlobalValue);
  Init__fixed_field(core::Symbol_O,3,SMART_PTR_OFFSET,_Function);
  Init__fixed_field(core::Symbol_O,4,SMART_PTR_OFFSET,_SetfFunction);
  Init__fixed_field(core::Symbol_O,5,SMART_PTR_OFFSET,_PropertyList);

  Init_class_kind(core::FuncallableInstance_O);
  Init__fixed_field(core::FuncallableInstance_O,0,SMART_PTR_OFFSET,_Rack);
  Init__fixed_field(core::FuncallableInstance_O,1,SMART_PTR_OFFSET,_Class);
  Init__fixed_field(core::FuncallableInstance_O,2,SMART_PTR_OFFSET,_CompiledDispatchFunction);

  Init_templated_kind(core::BuiltinClosure_O);
  Init__fixed_field( core::BuiltinClosure_O, 0,SMART_PTR_OFFSET,_lambdaListHandler);
  
  Init_class_kind(core::ClosureWithSlots_O);
  Init__variable_array0(core::ClosureWithSlots_O,_Slots._Data);
  Init__variable_capacity(core::ClosureWithSlots_O,value_type,_Slots._MaybeSignedLength,_Slots._MaybeSignedLength);
  Init__variable_field(core::ClosureWithSlots_O,SMART_PTR_OFFSET,0,"only",0);

  Init_templated_kind( core::WrappedPointer_O );
  Init__fixed_field( core::WrappedPointer_O, 0, SMART_PTR_OFFSET, Class_ );

  Init_class_kind(core::Package_O);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _InternalSymbols);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _ExternalSymbols);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _Shadowing);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _Name);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _Nicknames);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _LocalNicknames);
  Init__fixed_field(core::Package_O, 0, SMART_PTR_OFFSET, _Documentation);
  

  Init_class_kind(core::LambdaListHandler_O);
  Init__fixed_field(core::LambdaListHandler_O,0,SMART_PTR_OFFSET,_ClassifiedSymbolList);
  Init__fixed_field(core::LambdaListHandler_O,1,POINTER_OFFSET,_SpecialSymbolSet.theObject);
#if 0
 {  fixed_field, POINTER_OFFSET, sizeof(UnknownType), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_SpecialSymbolSet.theObject), "_SpecialSymbolSet.theObject" }, // atomic: NIL public: (T T) fixable: RAW-TAGGED-POINTER-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::List_V>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_DeclareSpecifierList), "_DeclareSpecifierList" }, // atomic: NIL public: (T) fixable: SMART-PTR-FIX good-name: T
 {  fixed_field, TAGGED_POINTER_OFFSET, sizeof(gctools::tagged_pointer<gctools::GCVector_moveable<core::RequiredArgument>>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_RequiredArguments._Vector._Contents), "_RequiredArguments._Vector._Contents" }, // atomic: NIL public: (T T T) fixable: TAGGED-POINTER-FIX good-name: T
 {  fixed_field, TAGGED_POINTER_OFFSET, sizeof(gctools::tagged_pointer<gctools::GCVector_moveable<core::OptionalArgument>>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_OptionalArguments._Vector._Contents), "_OptionalArguments._Vector._Contents" }, // atomic: NIL public: (T T T) fixable: TAGGED-POINTER-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::T_O>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_RestArgument._ArgTarget), "_RestArgument._ArgTarget" }, // atomic: NIL public: (T T) fixable: SMART-PTR-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::T_O>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_KeyFlag), "_KeyFlag" }, // atomic: NIL public: (T) fixable: SMART-PTR-FIX good-name: T
 {  fixed_field, TAGGED_POINTER_OFFSET, sizeof(gctools::tagged_pointer<gctools::GCVector_moveable<core::KeywordArgument>>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_KeywordArguments._Vector._Contents), "_KeywordArguments._Vector._Contents" }, // atomic: NIL public: (T T T) fixable: TAGGED-POINTER-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::T_O>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_AllowOtherKeys), "_AllowOtherKeys" }, // atomic: NIL public: (T) fixable: SMART-PTR-FIX good-name: T
 {  fixed_field, TAGGED_POINTER_OFFSET, sizeof(gctools::tagged_pointer<gctools::GCVector_moveable<core::AuxArgument>>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_AuxArguments._Vector._Contents), "_AuxArguments._Vector._Contents" }, // atomic: NIL public: (T T T) fixable: TAGGED-POINTER-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::SimpleString_O>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_Comment), "_Comment" }, // atomic: NIL public: (T) fixable: SMART-PTR-FIX good-name: T
 {  fixed_field, SMART_PTR_OFFSET, sizeof(gctools::smart_ptr<core::T_O>), __builtin_offsetof(SAFE_TYPE_MACRO(core::LambdaListHandler_O),_LexicalVariableNamesForDebugging), "_LexicalVariableNamesForDebugging" }, // atomic: NIL public: (T) fixable: SMART-PTR-FIX good-name: T
#endif


     Init_class_kind(core::VaList_dummy_O);
     Init_class_kind(core::Unused_dummy_O);
     Init_class_kind(core::ClassHolder_O);
     Init_class_kind(core::FdSet_O);
     Init_class_kind(core::SymbolToEnumConverter_O);
     Init_class_kind(llvmo::Attribute_O);
     Init_class_kind(core::LambdaListHandler_O);
     Init_class_kind(llvmo::AttributeSet_O);
     Init_class_kind(core::ClassRepCreator_O);
     Init_class_kind(core::DerivableCxxClassCreator_O);
     Init_class_kind(core::FuncallableInstanceCreator_O);
     Init_class_kind(clbind::DummyCreator_O);
     Init_class_kind(core::InstanceCreator_O);
     Init_class_kind(core::StandardClassCreator_O);
     Init_class_kind(core::SpecialForm_O);
     Init_class_kind(core::TranslationFunctor_O);
     Init_class_kind(core::SingleDispatchGenericFunctionClosure_O);
     Init_class_kind(core::ImmobileObject_O);
     Init_class_kind(core::WeakPointer_O);
     Init_class_kind(llvmo::DebugLoc_O);
     Init_class_kind(core::Pointer_O);
     Init_class_kind(clasp_ffi::ForeignData_O);
     Init_class_kind(core::CxxObject_O);
     Init_class_kind(core::NativeVector_float_O);
     Init_class_kind(llvmo::MDBuilder_O);
     Init_class_kind(mp::ConditionVariable_O);
     Init_class_kind(core::NativeVector_double_O);
     Init_class_kind(core::NativeVector_int_O);
     Init_class_kind(llvmo::FunctionCallee_O);
     Init_class_kind(core::Serializer_O);
     Init_class_kind(llvmo::DINodeArray_O);
     Init_class_kind(mp::Mutex_O);
     Init_class_kind(mp::RecursiveMutex_O);
     Init_class_kind(llvmo::DITypeRefArray_O);
     Init_class_kind(mp::SharedMutex_O);
     Init_class_kind(mp::Process_O);
     Init_class_kind(core::SingleDispatchMethod_O);
     Init_class_kind(core::Iterator_O);
     Init_class_kind(core::DirectoryIterator_O);
     Init_class_kind(core::RecursiveDirectoryIterator_O);
     Init_class_kind(core::Array_O);
     Init_class_kind(core::MDArray_O);
     Init_class_kind(core::MDArray_int16_t_O);
     Init_class_kind(core::MDArray_int8_t_O);
     Init_class_kind(core::MDArray_int32_t_O);
     Init_class_kind(core::MDArray_byte4_t_O);
     Init_class_kind(core::MDArray_float_O);
     Init_class_kind(core::MDArray_size_t_O);
     Init_class_kind(core::MDArray_byte8_t_O);
     Init_class_kind(core::MDArray_int64_t_O);
     Init_class_kind(core::MDArray_byte32_t_O);
     Init_class_kind(core::MDArray_byte2_t_O);
     Init_class_kind(core::MDArray_int2_t_O);
     Init_class_kind(core::MDArray_fixnum_O);
     Init_class_kind(core::MDArrayBaseChar_O);
     Init_class_kind(core::MDArray_byte64_t_O);
     Init_class_kind(core::MDArrayCharacter_O);
     Init_class_kind(core::MDArrayT_O);
     Init_class_kind(core::MDArrayBit_O);
     Init_class_kind(core::MDArray_byte16_t_O);
     Init_class_kind(core::SimpleMDArray_O);
     Init_class_kind(core::SimpleMDArray_int8_t_O);
     Init_class_kind(core::SimpleMDArray_double_O);
     Init_class_kind(core::SimpleMDArray_byte32_t_O);
     Init_class_kind(core::SimpleMDArrayT_O);
     Init_class_kind(core::SimpleMDArray_int2_t_O);
     Init_class_kind(core::SimpleMDArray_byte4_t_O);
     Init_class_kind(core::SimpleMDArray_int32_t_O);
     Init_class_kind(core::SimpleMDArray_float_O);
     Init_class_kind(core::SimpleMDArray_int16_t_O);
     Init_class_kind(core::SimpleMDArray_size_t_O);
     Init_class_kind(core::SimpleMDArray_int4_t_O);
     Init_class_kind(core::SimpleMDArrayCharacter_O);
     Init_class_kind(core::SimpleMDArray_byte2_t_O);
     Init_class_kind(core::SimpleMDArray_fixnum_O);
     Init_class_kind(core::SimpleMDArray_byte16_t_O);
     Init_class_kind(core::SimpleMDArrayBaseChar_O);
     Init_class_kind(core::SimpleMDArray_byte64_t_O);
     Init_class_kind(core::SimpleMDArrayBit_O);
     Init_class_kind(core::SimpleMDArray_byte8_t_O);
     Init_class_kind(core::SimpleMDArray_int64_t_O);
     Init_class_kind(core::MDArray_int4_t_O);
     Init_class_kind(core::MDArray_double_O);
     Init_class_kind(core::ComplexVector_O);
     Init_class_kind(core::ComplexVector_double_O);
     Init_class_kind(core::ComplexVector_int8_t_O);
     Init_class_kind(core::ComplexVector_byte64_t_O);
     Init_class_kind(core::ComplexVector_T_O);
     Init_class_kind(core::ComplexVector_int2_t_O);
     Init_class_kind(core::ComplexVector_int32_t_O);
     Init_class_kind(core::ComplexVector_byte16_t_O);
     Init_class_kind(core::ComplexVector_float_O);
     Init_class_kind(core::ComplexVector_int16_t_O);
     Init_class_kind(core::ComplexVector_int4_t_O);
     Init_class_kind(core::ComplexVector_size_t_O);
     Init_class_kind(core::ComplexVector_byte2_t_O);
     Init_class_kind(core::ComplexVector_byte8_t_O);
     Init_class_kind(core::ComplexVector_byte32_t_O);
     Init_class_kind(core::BitVectorNs_O);
     Init_class_kind(core::StrNs_O);
     Init_class_kind(core::Str8Ns_O);
     Init_class_kind(core::StrWNs_O);
     Init_class_kind(core::ComplexVector_byte4_t_O);
     Init_class_kind(core::ComplexVector_fixnum_O);
     Init_class_kind(core::ComplexVector_int64_t_O);
     Init_class_kind(core::AbstractSimpleVector_O);
     Init_class_kind(core::SimpleString_O);
     Init_class_kind(core::SimpleCharacterString_O);
     Init_class_kind(core::SimpleBaseString_O);
     Init_class_kind(core::SimpleVector_int16_t_O);
     Init_class_kind(core::SimpleVector_byte16_t_O);
     Init_class_kind(core::SimpleBitVector_O);
     Init_class_kind(core::SimpleVector_int4_t_O);
     Init_class_kind(core::SimpleVector_byte32_t_O);
     Init_class_kind(core::SimpleVector_size_t_O);
     Init_class_kind(core::SimpleVector_double_O);
     Init_class_kind(core::SimpleVector_byte64_t_O);
     Init_class_kind(core::SimpleVector_int2_t_O);
     Init_class_kind(core::SimpleVector_int64_t_O);
     Init_class_kind(core::SimpleVector_fixnum_O);
     Init_class_kind(core::SimpleVector_int8_t_O);
     Init_class_kind(core::SimpleVector_float_O);
     Init_class_kind(core::SimpleVector_O);
     Init_class_kind(core::SimpleVector_byte8_t_O);
     Init_class_kind(core::SimpleVector_byte2_t_O);
     Init_class_kind(core::SimpleVector_int32_t_O);
     Init_class_kind(core::SimpleVector_byte4_t_O);
     Init_class_kind(core::Null_O);
     Init_class_kind(core::Character_dummy_O);
     Init_class_kind(llvmo::DataLayout_O);
     Init_class_kind(core::LoadTimeValues_O);
     Init_class_kind(core::SharpEqualWrapper_O);
     Init_class_kind(llvmo::ClaspJIT_O);
     Init_class_kind(core::Readtable_O);
     Init_class_kind(core::PosixTime_O);
     Init_class_kind(core::Exposer_O);
     Init_class_kind(core::CoreExposer_O);
     Init_class_kind(asttooling::AsttoolingExposer_O);
     Init_class_kind(llvmo::StructLayout_O);
     Init_class_kind(core::PosixTimeDuration_O);
     Init_class_kind(clasp_ffi::ForeignTypeSpec_O);
     Init_class_kind(core::Instance_O);
     Init_class_kind(core::DerivableCxxObject_O);
     Init_class_kind(clbind::ClassRep_O);
     Init_class_kind(core::SmallMap_O);
     Init_class_kind(mpip::Mpi_O);
     Init_class_kind(core::ExternalObject_O);
     Init_class_kind(llvmo::Pass_O);
     Init_class_kind(llvmo::ModulePass_O);
     Init_class_kind(llvmo::ImmutablePass_O);
     Init_class_kind(llvmo::TargetLibraryInfoWrapperPass_O);
     Init_class_kind(llvmo::FunctionPass_O);
     Init_class_kind(llvmo::ExecutionEngine_O);
     Init_class_kind(llvmo::MCSubtargetInfo_O);
     Init_class_kind(llvmo::TargetSubtargetInfo_O);
     Init_class_kind(llvmo::Type_O);
     Init_class_kind(llvmo::FunctionType_O);
     Init_class_kind(llvmo::CompositeType_O);
     Init_class_kind(llvmo::SequentialType_O);
     Init_class_kind(llvmo::PointerType_O);
     Init_class_kind(llvmo::ArrayType_O);
     Init_class_kind(llvmo::VectorType_O);
     Init_class_kind(llvmo::StructType_O);
     Init_class_kind(llvmo::IntegerType_O);
     Init_class_kind(llvmo::JITDylib_O);
     Init_class_kind(llvmo::DIContext_O);
     Init_class_kind(llvmo::TargetPassConfig_O);
     Init_class_kind(llvmo::IRBuilderBase_O);
     Init_class_kind(llvmo::IRBuilder_O);
     Init_class_kind(llvmo::APFloat_O);
     Init_class_kind(llvmo::APInt_O);
     Init_class_kind(llvmo::DIBuilder_O);
     Init_class_kind(llvmo::SectionedAddress_O);
     Init_class_kind(llvmo::EngineBuilder_O);
     Init_class_kind(llvmo::PassManagerBase_O);
     Init_class_kind(llvmo::PassManager_O);
     Init_class_kind(llvmo::FunctionPassManager_O);
     Init_class_kind(llvmo::Metadata_O);
     Init_class_kind(llvmo::MDNode_O);
     Init_class_kind(llvmo::DINode_O);
     Init_class_kind(llvmo::DIVariable_O);
     Init_class_kind(llvmo::DILocalVariable_O);
     Init_class_kind(llvmo::DIScope_O);
     Init_class_kind(llvmo::DIFile_O);
     Init_class_kind(llvmo::DIType_O);
     Init_class_kind(llvmo::DICompositeType_O);
     Init_class_kind(llvmo::DIDerivedType_O);
     Init_class_kind(llvmo::DIBasicType_O);
     Init_class_kind(llvmo::DISubroutineType_O);
     Init_class_kind(llvmo::DILocalScope_O);
     Init_class_kind(llvmo::DISubprogram_O);
     Init_class_kind(llvmo::DILexicalBlockBase_O);
     Init_class_kind(llvmo::DILexicalBlock_O);
     Init_class_kind(llvmo::DICompileUnit_O);
     Init_class_kind(llvmo::DIExpression_O);
     Init_class_kind(llvmo::DILocation_O);
     Init_class_kind(llvmo::ValueAsMetadata_O);
     Init_class_kind(llvmo::MDString_O);
     Init_class_kind(llvmo::Value_O);
     Init_class_kind(llvmo::Argument_O);
     Init_class_kind(llvmo::BasicBlock_O);
     Init_class_kind(llvmo::MetadataAsValue_O);
     Init_class_kind(llvmo::User_O);
     Init_class_kind(llvmo::Instruction_O);
     Init_class_kind(llvmo::UnaryInstruction_O);
     Init_class_kind(llvmo::VAArgInst_O);
     Init_class_kind(llvmo::LoadInst_O);
     Init_class_kind(llvmo::AllocaInst_O);
     Init_class_kind(llvmo::SwitchInst_O);
     Init_class_kind(llvmo::AtomicRMWInst_O);
     Init_class_kind(llvmo::LandingPadInst_O);
     Init_class_kind(llvmo::StoreInst_O);
     Init_class_kind(llvmo::UnreachableInst_O);
     Init_class_kind(llvmo::ReturnInst_O);
     Init_class_kind(llvmo::ResumeInst_O);
     Init_class_kind(llvmo::AtomicCmpXchgInst_O);
     Init_class_kind(llvmo::FenceInst_O);
     Init_class_kind(llvmo::CallBase_O);
     Init_class_kind(llvmo::CallInst_O);
     Init_class_kind(llvmo::InvokeInst_O);
     Init_class_kind(llvmo::PHINode_O);
     Init_class_kind(llvmo::IndirectBrInst_O);
     Init_class_kind(llvmo::BranchInst_O);
     Init_class_kind(llvmo::Constant_O);
     Init_class_kind(llvmo::GlobalValue_O);
     Init_class_kind(llvmo::Function_O);
     Init_class_kind(llvmo::GlobalVariable_O);
     Init_class_kind(llvmo::BlockAddress_O);
     Init_class_kind(llvmo::ConstantDataSequential_O);
     Init_class_kind(llvmo::ConstantDataArray_O);
     Init_class_kind(llvmo::ConstantStruct_O);
     Init_class_kind(llvmo::ConstantInt_O);
     Init_class_kind(llvmo::ConstantFP_O);
     Init_class_kind(llvmo::ConstantExpr_O);
     Init_class_kind(llvmo::ConstantPointerNull_O);
     Init_class_kind(llvmo::UndefValue_O);
     Init_class_kind(llvmo::ConstantArray_O);
     Init_class_kind(llvmo::TargetMachine_O);
     Init_class_kind(llvmo::LLVMTargetMachine_O);
     Init_class_kind(llvmo::ThreadSafeContext_O);
     Init_class_kind(llvmo::NamedMDNode_O);
     Init_class_kind(llvmo::Triple_O);
     Init_class_kind(llvmo::DWARFContext_O);
     Init_class_kind(llvmo::TargetOptions_O);
     Init_class_kind(llvmo::ObjectFile_O);
     Init_class_kind(llvmo::LLVMContext_O);
     Init_class_kind(llvmo::PassManagerBuilder_O);
     Init_class_kind(llvmo::Module_O);
     Init_class_kind(llvmo::Target_O);
     Init_class_kind(llvmo::Linker_O);
     Init_class_kind(core::Rack_O);
     Init_class_kind(core::SmallMultimap_O);
     Init_class_kind(core::Sigset_O);
     Init_class_kind(core::Environment_O);
     Init_class_kind(core::GlueEnvironment_O);
     Init_class_kind(core::LexicalEnvironment_O);
     Init_class_kind(core::RuntimeVisibleEnvironment_O);
     Init_class_kind(core::FunctionValueEnvironment_O);
     Init_class_kind(core::TagbodyEnvironment_O);
     Init_class_kind(core::BlockEnvironment_O);
     Init_class_kind(core::ValueEnvironment_O);
     Init_class_kind(core::CompileTimeEnvironment_O);
     Init_class_kind(core::CatchEnvironment_O);
     Init_class_kind(core::MacroletEnvironment_O);
     Init_class_kind(core::SymbolMacroletEnvironment_O);
     Init_class_kind(core::FunctionContainerEnvironment_O);
     Init_class_kind(core::UnwindProtectEnvironment_O);
     Init_class_kind(core::ActivationFrame_O);
     Init_class_kind(core::ValueFrame_O);
     Init_class_kind(core::FunctionFrame_O);
     Init_class_kind(core::RandomState_O);
     Init_class_kind(core::HashTableBase_O);
     Init_class_kind(core::WeakKeyHashTable_O);
     Init_class_kind(core::HashTable_O);
     Init_class_kind(core::HashTableEqualp_O);
     Init_class_kind(core::HashTableEq_O);
     Init_class_kind(core::HashTableEql_O);
     Init_class_kind(core::HashTableEqual_O);
     Init_class_kind(llvmo::InsertPoint_O);
     Init_class_kind(core::Scope_O);
     Init_class_kind(core::FileScope_O);
     Init_class_kind(core::Path_O);
     Init_class_kind(core::Pathname_O);
     Init_class_kind(core::LogicalPathname_O);
     Init_class_kind(core::Number_O);
     Init_class_kind(core::Real_O);
     Init_class_kind(core::Rational_O);
     Init_class_kind(core::Ratio_O);
     Init_class_kind(core::Integer_O);
     Init_class_kind(core::Bignum_O);
     Init_class_kind(core::Fixnum_dummy_O);
     Init_class_kind(core::Float_O);
     Init_class_kind(core::DoubleFloat_O);
     Init_class_kind(core::SingleFloat_dummy_O);
     Init_class_kind(core::LongFloat_O);
     Init_class_kind(core::ShortFloat_O);
     Init_class_kind(core::Complex_O);
     Init_class_kind(core::Stream_O);
     Init_class_kind(core::AnsiStream_O);
     Init_class_kind(core::TwoWayStream_O);
     Init_class_kind(core::SynonymStream_O);
     Init_class_kind(core::ConcatenatedStream_O);
     Init_class_kind(core::FileStream_O);
     Init_class_kind(core::IOFileStream_O);
     Init_class_kind(core::IOStreamStream_O);
     Init_class_kind(core::BroadcastStream_O);
     Init_class_kind(core::StringStream_O);
     Init_class_kind(core::StringOutputStream_O);
     Init_class_kind(core::StringInputStream_O);
     Init_class_kind(core::EchoStream_O);
     Init_class_kind(core::FileStatus_O);
     Init_class_kind(core::InvocationHistoryFrameIterator_O);
     Init_class_kind(core::SourcePosInfo_O);
     Init_class_kind(core::IntArray_O);
     Init_class_kind(core::DirectoryEntry_O);
     Init_class_kind(core::LightUserData_O);
     Init_class_kind(core::UserData_O);
     Init_class_kind(core::Record_O);
     Init_class_kind(clbind::ClassRegistry_O);
     Init_class_kind(core::Frame_O);
     Init_class_kind(core::MultiStringBuffer_O);
     Init_class_kind(core::Cons_O);
     Init_class_kind(asttooling::AstVisitor_O);

     Init_templated_kind(core::WrappedPointer_O);
     Init_templated_kind(core::Creator_O);
     Init_templated_kind(clbind::ConstructorCreator_O);
     Init_templated_kind(core::Closure_O);
     Init_templated_kind(core::BuiltinClosure_O);

};


void initialize_clasp()
{
  // The bootStrapCoreSymbolMap keeps track of packages and symbols while they
  // are half-way initialized.
  MPS_LOG("initialize_clasp");
  core::BootStrapCoreSymbolMap bootStrapCoreSymbolMap;
  setup_bootstrap_packages(&bootStrapCoreSymbolMap);

  MPS_LOG("initialize_clasp allocate_symbols");
  allocate_symbols(&bootStrapCoreSymbolMap);

  MPS_LOG("initialize_clasp set_static_class_symbols");
  set_static_class_symbols(&bootStrapCoreSymbolMap);

  ShiftedStamp TheClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheClass_stamp));
  ShiftedStamp TheBuiltInClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheBuiltInClass_stamp));
  ShiftedStamp TheStandardClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheStandardClass_stamp));
  ShiftedStamp TheStructureClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheStructureClass_stamp));
  ShiftedStamp TheDerivableCxxClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheDerivableCxxClass_stamp));
  ShiftedStamp TheClbindCxxClass_stamp = gctools::NextStampWtag(gctools::Header_s::rack_wtag);
  ASSERT(Header_s::StampWtagMtag::is_rack_shifted_stamp(TheClbindCxxClass_stamp));
//  global_TheClassRep_stamp = gctools::GCStamp<clbind::ClassRep_O>::Stamp;
  _lisp->_Roots._TheClass = allocate_one_metaclass<core::StandardClassCreator_O>(TheClass_stamp,cl::_sym_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheBuiltInClass = allocate_one_metaclass<core::StandardClassCreator_O>(TheBuiltInClass_stamp,cl::_sym_built_in_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheStandardClass = allocate_one_metaclass<core::StandardClassCreator_O>(TheStandardClass_stamp,cl::_sym_standard_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheStructureClass = allocate_one_metaclass<core::StandardClassCreator_O>(TheStructureClass_stamp,cl::_sym_structure_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheDerivableCxxClass = allocate_one_metaclass<core::DerivableCxxClassCreator_O>(TheDerivableCxxClass_stamp,core::_sym_derivable_cxx_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheClbindCxxClass = allocate_one_metaclass<core::ClassRepCreator_O>(TheClbindCxxClass_stamp,core::_sym_clbind_cxx_class,_Unbound<core::Instance_O>());
  _lisp->_Roots._TheClass->_Class = _lisp->_Roots._TheStandardClass;
  _lisp->_Roots._TheBuiltInClass->_Class = _lisp->_Roots._TheStandardClass;
  _lisp->_Roots._TheStandardClass->_Class = _lisp->_Roots._TheStandardClass;
  _lisp->_Roots._TheStructureClass->_Class = _lisp->_Roots._TheStandardClass;
  _lisp->_Roots._TheDerivableCxxClass->_Class = _lisp->_Roots._TheStandardClass;
  _lisp->_Roots._TheClbindCxxClass->_Class = _lisp->_Roots._TheStandardClass;
  MPS_LOG("initialize_clasp ALLOCATE_ALL_CLASSES");
  #ifndef SCRAPING
   #define ALLOCATE_ALL_CLASSES
    #include INIT_CLASSES_INC_H
   #undef ALLOCATE_ALL_CLASSES
  #endif
  core_T_O_var->setInstanceBaseClasses(_Nil<core::T_O>());
  // ClassRep_O is initialized like other class objects - but we need to save it in a special system-wide variable
//  _lisp->_Roots._TheClassRep = clbind_ClassRep_O_var;
  
  create_packages();
  // have to do this before symbols are finalized so that keywords are all bound properly.
  gc::As<core::Package_sp>(_lisp->findPackage("KEYWORD"))->setKeywordPackage(true);
  
  define_builtin_cxx_classes();

  bootStrapCoreSymbolMap.finish_setup_of_symbols();

  // Define base classes
  #ifndef SCRAPING
   #define SET_BASES_ALL_CLASSES
    #include INIT_CLASSES_INC_H
   #undef SET_BASES_ALL_CLASSES
  #endif

    // Define base classes
  #ifndef SCRAPING
   #define CALCULATE_CLASS_PRECEDENCE_ALL_CLASSES
    #include INIT_CLASSES_INC_H
   #undef CALCULATE_CLASS_PRECEDENCE_ALL_CLASSES
  #endif

  _lisp->_Roots._TheClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());
  _lisp->_Roots._TheBuiltInClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheBuiltInClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheBuiltInClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheBuiltInClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());
  _lisp->_Roots._TheStandardClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheStandardClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheStandardClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheStandardClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());
  _lisp->_Roots._TheStructureClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheStructureClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheStructureClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheStructureClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());
  _lisp->_Roots._TheDerivableCxxClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheDerivableCxxClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheDerivableCxxClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheDerivableCxxClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());
  _lisp->_Roots._TheClbindCxxClass->stamp_set(TheStandardClass_stamp);
  _lisp->_Roots._TheClbindCxxClass->instanceSet(core::Instance_O::REF_CLASS_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheClbindCxxClass->instanceSet(core::Instance_O::REF_CLASS_DIRECT_SLOTS,_Nil<core::T_O>());
  _lisp->_Roots._TheClbindCxxClass->instanceSet(core::Instance_O::REF_CLASS_DEFAULT_INITARGS,_Nil<core::T_O>());

  _lisp->_Roots._TheBuiltInClass->setInstanceBaseClasses(core::Cons_O::createList(_lisp->_Roots._TheClass));
  _lisp->_Roots._TheStandardClass->setInstanceBaseClasses(core::Cons_O::createList(_lisp->_Roots._TheClass));
  _lisp->_Roots._TheStructureClass->setInstanceBaseClasses(core::Cons_O::createList(_lisp->_Roots._TheClass));
  _lisp->_Roots._TheDerivableCxxClass->setInstanceBaseClasses(core::Cons_O::createList(_lisp->_Roots._TheClass));
  _lisp->_Roots._TheClbindCxxClass->setInstanceBaseClasses(core::Cons_O::createList(_lisp->_Roots._TheClass));

  reg::lisp_registerClassSymbol<core::Character_I>(cl::_sym_character);
  reg::lisp_registerClassSymbol<core::Fixnum_I>(cl::_sym_fixnum);
  reg::lisp_registerClassSymbol<core::SingleFloat_I>(cl::_sym_single_float);

  initialize_enums();

// Moved to lisp.cc
//  initialize_functions();
  // initialize methods???
//  initialize_source_info();
};

extern "C" {

#ifndef SCRAPING
#include C_WRAPPERS
#endif
};
#endif // #ifndef SCRAPING at top


