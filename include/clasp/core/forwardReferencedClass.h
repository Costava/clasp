/*
    File: forwardReferencedClass.h
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
#if 0
#ifndef _core_ForwardReferencedClass_H
#define _core_ForwardReferencedClass_H

#include <clasp/core/foundation.h>
#include <clasp/core/metaClass.h>

namespace core {

FORWARD(ForwardReferencedClass);

/*! Clisp says that forward-referenced-class should not be a subclass of class and specializer but should be a subclass of metaobject
 * google: forward-referenced-class clisp
 http://clisp.podval.org/impnotes/mop-overview.html#forward-referenced-class-clisp
*/
class ForwardReferencedClass_O : public Class_O {
  LISP_META_CLASS(core::StandardClass_O);
  LISP_CLASS(core, CorePkg, ForwardReferencedClass_O, "ForwardReferencedClass",Class_O);
  //    DECLARE_ARCHIVE();
public: // Simple default ctor/dtor
 ForwardReferencedClass_O(gctools::Stamp is) : Class_O(is) {};

public:
  void initialize();

GCPRIVATE: // instance variables here
//  BuiltInClass_sp _InstanceCoreClass;

public: // Functions here
//  void setInstanceCoreClass(BuiltInClass_sp bic);

  void defineYourSlotsFromBinderArchiveNode(ArchiveP binderNode);
};

}; /* core */

template <>
struct gctools::GCInfo<core::ForwardReferencedClass_O> {
  static bool constexpr NeedsInitialization = true;
  static bool constexpr NeedsFinalization = false;
  static GCInfo_policy constexpr Policy = normal;
};


namespace core {
  // Specialize BuiltInObjectCreator for ForwardReferencedClass_O
  template <>
    class BuiltInObjectCreator<ForwardReferencedClass_O> : public core::Creator_O {
  public:
    typedef core::Creator_O TemplatedBase;
  public:
    DISABLE_NEW();
    size_t templatedSizeof() const { return sizeof(BuiltInObjectCreator<ForwardReferencedClass_O>); };
    virtual void describe() const {
      printf("BuiltInObjectCreator for class %s  sizeof_instances-> %zu\n", _rep_(reg::lisp_classSymbol<ForwardReferencedClass_O>()).c_str(), sizeof(ForwardReferencedClass_O));
    }
    virtual core::T_sp creator_allocate() {
      // BuiltInObjectCreator<ForwardReferencedClass_O> uses a different allocation method
      // that assigns the NextStamp to the new ForwardReferencedClass
      GC_ALLOCATE_VARIADIC(ForwardReferencedClass_O, obj, gctools::NextStamp() );
      return obj;
    }
    virtual void searcher(){};
  };


};

#endif /* _core_ForwardReferencedClass_H */
#endif
