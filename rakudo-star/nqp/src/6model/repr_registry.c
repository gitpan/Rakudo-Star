/* This is an implementation of a representation registry. It keeps track of
 * all of the available representations, and is responsible for building them
 * at startup. */

#define PARROT_IN_EXTENSION
#include "parrot/parrot.h"
#include "parrot/extend.h"
#include "sixmodelobject.h"
#include "reprs/KnowHOWREPR.h"
#include "reprs/P6opaque.h"
#include "reprs/P6int.h"
#include "reprs/P6num.h"
#include "reprs/P6str.h"
#include "reprs/HashAttrStore.h"
#include "reprs/Uninstantiable.h"
#include "repr_registry.h"

/* An array mapping representation IDs to function tables. */
static REPROps **repr_registry = NULL;

/* Number of representations registered so far. */
static INTVAL num_reprs = 0;

/* Hash mapping representation names to IDs. */
static PMC *repr_name_to_id_map = NULL;

/* Default REPR function handlers. */
PARROT_DOES_NOT_RETURN
static void die_no_attrs(PARROT_INTERP, STRING *repr_name) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss representation does not support attribute storage", repr_name);
}
static PMC * default_get_attribute_boxed(PARROT_INTERP, STable *st, void *data, PMC *class_handle, STRING *name, INTVAL hint) {
    die_no_attrs(interp, st->REPR->name);
}
static void * default_get_attribute_ref(PARROT_INTERP, STable *st, void *data, PMC *class_handle, STRING *name, INTVAL hint) {
    die_no_attrs(interp, st->REPR->name);
}
static void default_bind_attribute_boxed(PARROT_INTERP, STable *st, void *data, PMC *class_handle, STRING *name, INTVAL hint, PMC *value) {
    die_no_attrs(interp, st->REPR->name);
}
static void default_bind_attribute_ref(PARROT_INTERP, STable *st, void *data, PMC *class_handle, STRING *name, INTVAL hint, void *value) {
    die_no_attrs(interp, st->REPR->name);
}
static INTVAL default_is_attribute_initialized(PARROT_INTERP, STable *st, void *data, PMC *class_handle, STRING *name, INTVAL hint) {
    die_no_attrs(interp, st->REPR->name);
}
static INTVAL default_hint_for(PARROT_INTERP, STable *st, PMC *class_handle, STRING *name) {
    return NO_HINT;
}
static void default_set_int(PARROT_INTERP, STable *st, void *data, INTVAL value) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot box a native int", st->REPR->name);
}
static INTVAL default_get_int(PARROT_INTERP, STable *st, void *data) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot unbox to a native int", st->REPR->name);
}
static void default_set_num(PARROT_INTERP, STable *st, void *data, FLOATVAL value) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot box a native num", st->REPR->name);
}
static FLOATVAL default_get_num(PARROT_INTERP, STable *st, void *data) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot unbox to a native num", st->REPR->name);
}
static void default_set_str(PARROT_INTERP, STable *st, void *data, STRING *value) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot box a native string", st->REPR->name);
}
static STRING * default_get_str(PARROT_INTERP, STable *st, void *data) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot unbox to a native string", st->REPR->name);
}
static void * default_get_boxed_ref(PARROT_INTERP, STable *st, void *data, INTVAL repr_id) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss cannot box other types", st->REPR->name);
}
PARROT_DOES_NOT_RETURN
static void die_no_idx(PARROT_INTERP, STRING *repr_name) {
    Parrot_ex_throw_from_c_args(interp, NULL, EXCEPTION_INVALID_OPERATION,
            "%Ss representation does not support indexed storage", repr_name);
}
static void * default_at_pos_ref(PARROT_INTERP, STable *st, void *data, INTVAL index) {
    die_no_idx(interp, st->REPR->name);
}
static PMC * default_at_pos_boxed(PARROT_INTERP, STable *st, void *data, INTVAL index) {
    die_no_idx(interp, st->REPR->name);
}
static void default_bind_pos_ref(PARROT_INTERP, STable *st, void *data, INTVAL index, void *addr) {
    die_no_idx(interp, st->REPR->name);
}
static void default_bind_pos_boxed(PARROT_INTERP, STable *st, void *data, INTVAL index, PMC *obj) {
    die_no_idx(interp, st->REPR->name);
}
static INTVAL default_elems(PARROT_INTERP, STable *st, void *data) {
    die_no_idx(interp, st->REPR->name);
}
static void default_preallocate(PARROT_INTERP, STable *st, void *data, INTVAL count) {
    die_no_idx(interp, st->REPR->name);
}
static void default_trim_to(PARROT_INTERP, STable *st, void *data, INTVAL count) {
    die_no_idx(interp, st->REPR->name);
}
static void default_make_hole(PARROT_INTERP, STable *st, void *data, INTVAL at_index, INTVAL count) {
    die_no_idx(interp, st->REPR->name);
}
static void default_delete_elems(PARROT_INTERP, STable *st, void *data, INTVAL at_index, INTVAL count) {
    die_no_idx(interp, st->REPR->name);
}
static STable * default_get_elem_stable(PARROT_INTERP, STable *st) {
    die_no_idx(interp, st->REPR->name);
}

/* Set default attribute functions on a REPR that lacks them. */
static void add_default_attr_funcs(PARROT_INTERP, REPROps *repr) {
    repr->attr_funcs = mem_allocate_typed(REPROps_Attribute);
    repr->attr_funcs->get_attribute_boxed = default_get_attribute_boxed;
    repr->attr_funcs->get_attribute_ref = default_get_attribute_ref;
    repr->attr_funcs->bind_attribute_boxed = default_bind_attribute_boxed;
    repr->attr_funcs->bind_attribute_ref = default_bind_attribute_ref;
    repr->attr_funcs->is_attribute_initialized = default_is_attribute_initialized;
    repr->attr_funcs->hint_for = default_hint_for;
}

/* Set default boxing functions on a REPR that lacks them. */
static void add_default_box_funcs(PARROT_INTERP, REPROps *repr) {
    repr->box_funcs = mem_allocate_typed(REPROps_Boxing);
    repr->box_funcs->set_int = default_set_int;
    repr->box_funcs->get_int = default_get_int;
    repr->box_funcs->set_num = default_set_num;
    repr->box_funcs->get_num = default_get_num;
    repr->box_funcs->set_str = default_set_str;
    repr->box_funcs->get_str = default_get_str;
    repr->box_funcs->get_boxed_ref = default_get_boxed_ref;
}

/* Set default indexing functions on a REPR that lacks them. */
static void add_default_idx_funcs(PARROT_INTERP, REPROps *repr) {
    repr->idx_funcs = mem_allocate_typed(REPROps_Indexing);
    repr->idx_funcs->at_pos_ref = default_at_pos_ref;
    repr->idx_funcs->at_pos_boxed = default_at_pos_boxed;
    repr->idx_funcs->bind_pos_ref = default_bind_pos_ref;
    repr->idx_funcs->bind_pos_boxed = default_bind_pos_boxed;
    repr->idx_funcs->elems = default_elems;
    repr->idx_funcs->preallocate = default_preallocate;
    repr->idx_funcs->trim_to = default_trim_to;
    repr->idx_funcs->make_hole = default_make_hole;
    repr->idx_funcs->delete_elems = default_delete_elems;
    repr->idx_funcs->get_elem_stable = default_get_elem_stable;
}

/* Registers a representation. It this is ever made public, it should first be
 * made thread-safe. */
static void register_repr(PARROT_INTERP, STRING *name, REPROps *repr) {
    INTVAL ID = num_reprs;
    num_reprs++;
    if (repr_registry)
        repr_registry = (REPROps **)mem_sys_realloc(repr_registry, num_reprs * sizeof(REPROps *));
    else
        repr_registry = (REPROps **)mem_sys_allocate(num_reprs * sizeof(REPROps *));
    repr_registry[ID] = repr;
    VTABLE_set_integer_keyed_str(interp, repr_name_to_id_map, name, ID);
    repr->ID = ID;
    repr->name = name;
    if (!repr->attr_funcs)
        add_default_attr_funcs(interp, repr);
    if (!repr->box_funcs)
        add_default_box_funcs(interp, repr);
    if (!repr->idx_funcs)
        add_default_idx_funcs(interp, repr);
}

/* Dynamically registers a representation (that is, one defined outside of
 * the 6model core). */
static INTVAL REPR_register_dynamic(PARROT_INTERP, STRING *name, REPROps * (*reg) (PARROT_INTERP, void *, void *)) {
    REPROps *repr = reg(interp, wrap_object, create_stable);
    register_repr(interp, name, repr);
    return repr->ID;
}

/* Initializes the representations registry, building up all of the various
 * representations. */
void REPR_initialize_registry(PARROT_INTERP) {
    PMC *dyn_reg_func;
    
    /* Allocate name to ID map, and anchor it with the GC. */
    repr_name_to_id_map = Parrot_pmc_new(interp, enum_class_Hash);
    Parrot_pmc_gc_register(interp, repr_name_to_id_map);

    /* Add all core representations. */
    register_repr(interp, Parrot_str_new_constant(interp, "KnowHOWREPR"), 
        KnowHOWREPR_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "P6opaque"), 
        P6opaque_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "P6int"), 
        P6int_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "P6num"), 
        P6num_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "P6str"), 
        P6str_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "HashAttrStore"), 
        HashAttrStore_initialize(interp));
    register_repr(interp, Parrot_str_new_constant(interp, "Uninstantiable"),
        Uninstantiable_initialize(interp));

    /* Set up object for dynamically registering extra representations. */
    dyn_reg_func = Parrot_pmc_new(interp, enum_class_Pointer);
    VTABLE_set_pointer(interp, dyn_reg_func, REPR_register_dynamic);
    VTABLE_set_pmc_keyed_str(interp, interp->root_namespace,
        Parrot_str_new_constant(interp, "_REGISTER_REPR"), dyn_reg_func);
}

/* Get a representation's ID from its name. Note that the IDs may change so
 * it's best not to store references to them in e.g. the bytecode stream. */
INTVAL REPR_name_to_id(PARROT_INTERP, STRING *name) {
    return VTABLE_get_integer_keyed_str(interp, repr_name_to_id_map, name);
}

/* Gets a representation by ID. */
REPROps * REPR_get_by_id(PARROT_INTERP, INTVAL id) {
    return repr_registry[id];
}

/* Gets a representation by name. */
REPROps * REPR_get_by_name(PARROT_INTERP, STRING *name) {
    return repr_registry[VTABLE_get_integer_keyed_str(interp, repr_name_to_id_map, name)];
}
