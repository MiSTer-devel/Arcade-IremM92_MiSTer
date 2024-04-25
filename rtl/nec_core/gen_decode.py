import yaml
import sys

from anytree import Node, RenderTree, search, PostOrderIter

placeholders = {
    'MD': {
        'signal': 'mod',
    },
    'MEM': {
        'signal': 'rm',
    },
    'GP0': {
        'signal': 'reg0',
    },
    'GP1': {
        'signal': 'reg1',
    },
    'SR': {
        'signal': 'sreg',
    },
    'W': {
        'signal': 'width',
        'transform': lambda x: f"{x} ? WORD : BYTE"
    },
    'COND': {
        'signal': 'cond'
    },
    'ALU': {
        'signal': 'alu_operation',
        'transform': lambda x: f"alu_operation_e'({x})"
    },
    'SFT': {
        'signal': 'shift',
        'transform': lambda x: f"shift_operation_e'({x})"
    }
}

def is_ambiguous(case1, case2):
    for a, b in zip(case1, case2):
        if a == 'x' or b == 'x':
            continue
        if a != b:
            return False
    return True

def assign_src_dst(op_desc, assignments):
    def is_mem_type(x):
        return x in [ 'MODRM', 'DMEM', 'IO_DIRECT', 'IO_INDIRECT' ]
    src = op_desc.get('src')
    src0 = op_desc.get('src0', 'NONE')
    src1 = op_desc.get('src1', 'NONE')
    dst = op_desc.get('dst', 'NONE')

    if src:
        src0 = src
        src1 = 'NONE'

    mapping = { 'dest': dst, 'source0': src0, 'source1': src1 }

    found = None
    found_src = False
    found_dst = False

    if is_mem_type(dst):
        found = dst
        found_dst = True
    
    if is_mem_type(src0):
        found = src0
        found_src = True

    if is_mem_type(src1):
        found = src1
        found_src = True

    if found:
        if found == 'DMEM':
            assignments["rm"] = "3'b110"
            assignments["mod"] = "2'b00"
            assignments["disp_size"] = "calc_disp_size(3'b110, 2'b00)"
            found = 'MODRM'
            if found_dst:
                assignments['mem_write'] = '1'
            if found_src:
                assignments['mem_read'] = '1'
        elif found == 'MODRM':
            mod = assignments["mod"]
            rm = assignments["rm"]
            if found_dst:
                assignments['mem_write'] = f"{mod} != 2'b11"
            if found_src:
                assignments['mem_read'] = f"{mod} != 2'b11"
            assignments["disp_size"] = f"calc_disp_size({rm}, {mod})"
            assignments["segment"] = f"d.segment_override ? d.segment : calc_seg({rm}, {mod});"
        else:
            if found_dst:
                assignments['mem_write'] = "1"
            if found_src:
                assignments['mem_read'] = "1"
            assignments['io'] = "1"
            if found == "IO_DIRECT":
                assignments["disp_size"] = "1"

        for k in list(mapping.keys()):
            if is_mem_type(mapping[k]):
                mapping[k] = found

    for k, v in mapping.items():
        if v != 'NONE':
            assignments[k] = f"OPERAND_{v}"
    
    return assignments


def add_child(parent, match, assignments):
    existing = None
    for child in parent.children:
        if child.match == match:
            existing = child
    
    if existing:
        if existing.assignments != assignments:
            print(existing)
            raise "Oops"
        return existing
    
    return Node(match, parent=parent, match=match, assignments=assignments, comment='', prefix=False, decode_delay=0)

def add_nodes(root: Node, k: str, op_desc: dict):
    if not k.startswith('b'):
        return

    opcode = op_desc.get('op')

    k = k[1:]
    k = k.replace('_', '')

    k_size = (len(k) + 7) // 8

    k = k + ('x' * ((k_size * 8) - len(k)))
    nodes = []

    parent = root

    for x in range(k_size):
        segment = k[x*8:(x*8)+8]
        assign = {}

        for pid, desc in placeholders.items():
            idx = segment.find(pid)
            if idx != -1:
                start = 7 - idx
                end = 8 - (idx + len(pid))
                source = f"q[{start}:{end}]"
                if start == end:
                    source = f"q[{start}]"
                
                tr = desc.get('transform', None)
                if tr:
                    source = tr(source)
                assign[desc['signal']] = source
                segment = segment.replace(pid, 'x' * len(pid))
        
        parent = add_child(parent, segment, assign)

    assignments = parent.assignments

    prefix = False
    comment = op_desc.get('desc') or opcode

    if opcode:
        assignments["opcode"] = f"OP_{opcode}"
    
    opclass = op_desc.get('class')
    if opclass:
        assignments["opclass"] = opclass

    alu_op = op_desc.get('alu')
    if alu_op:
        assignments["alu_operation"] = f"ALU_OP_{alu_op}"
    
    sreg = op_desc.get('sreg')
    if sreg:
        assignments["sreg"] = sreg

    reg = op_desc.get('reg0')
    if reg:
        assignments["reg0"] = reg

    reg = op_desc.get('reg1')
    if reg:
        assignments["reg1"] = reg

    width = op_desc.get('width')
    if width:
        assignments["width"] = width

    decode_delay = op_desc.get('decode_delay', 0)
    
    push = op_desc.get('push')
    if push:
        if not isinstance(push, list):
            push = [ push ]
        agg = ' | '.join( [ f"STACK_{x}" for x in push ] )
        assignments["push"] = agg

    pop = op_desc.get('pop')
    if pop:
        if not isinstance(pop, list):
            pop = [ pop ]
        agg = ' | '.join( [ f"STACK_{x}" for x in pop ] )
        assignments["pop"] = agg

    segment = op_desc.get('segment')
    if segment:
        assignments['segment'] = segment
        assignments['segment_override'] = '1'
        prefix = True

    repeat = op_desc.get('repeat')
    if repeat:
        assignments['rep'] = repeat
        prefix = True

    buslock = op_desc.get('buslock')
    if buslock:
        assignments['buslock'] = '1'
        prefix = True

    parent.assignments = assign_src_dst(op_desc, assignments)

    parent.comment = comment
    parent.is_prefix = prefix
    parent.decode_delay = decode_delay

def node_state_name(node: Node) -> str:
    if node.parent:
        return node_state_name(node.parent) + f'_{node.match}'
    else:
        return 'ROOT'

input_name = 'hdl/opcodes.yaml'
output_name = 'hdl/opcodes.svh'
output_enumname = 'hdl/opcode_enums.yaml'

opcode_desc = yaml.safe_load(open(input_name, 'r'))


root = Node("ROOT")
for k, v in opcode_desc.items():
    add_nodes(root, k, v)


state_names = [ node_state_name(node) for node in PostOrderIter(root, lambda x: not x.is_leaf and not x.is_root) ]
enums = {
    'decode_state_e': {
        'values': [
            'INITIAL',
            'TERMINAL',
            'DELAY_1',
            'DELAY_2',
            'DELAY_3',
            'DELAY_4',
            'PREFIX_CONTINUE',
            'ILLEGAL'
        ] + state_names
    }
}

with open(output_enumname, 'wt') as fp:
    yaml.safe_dump(enums, fp)

fp = open(output_name, "wt")
for node in PostOrderIter(root, lambda x: not x.is_leaf):
    name = node_state_name(node)

    fp.write( f"task process_{name}(input bit [7:0] q);\n" )
    fp.write( f"  casex(q)\n" )
    children = list(node.children)
    children.sort(key=lambda x: x.match.count('x'))
    for child in children:
        fp.write( f"    8'b{child.match}: begin\n" )
        for sym, val in child.assignments.items():
            fp.write( f"      d.{sym} <= {val};\n" )
        if child.is_leaf and child.is_prefix:
            fp.write( f"      state <= PREFIX_CONTINUE;\n" )
        elif child.is_leaf:
            if child.decode_delay > 0:
                fp.write( f"      state <= DELAY_{child.decode_delay};\n" )
            else:
                fp.write( f"      state <= TERMINAL;\n" )
        else:
            fp.write( f"      state <= {node_state_name(child)};\n" )
        fp.write( f"    end\n" )
    fp.write( f"    default: begin\n" )
    fp.write( f"      state <= ILLEGAL;\n" )
    fp.write( f"    end\n" )
    fp.write( f"  endcase\n" )
    fp.write( f"endtask\n\n" )

fp.write( f"task process_decode(input bit [7:0] q);\n" )
fp.write( f"  case(state)\n" )
for name in state_names:
    fp.write( f"    {name}: process_{name}(q);\n" )
fp.write( f"    default: process_ROOT(q);\n" )
fp.write( f"  endcase\n" )
fp.write( f"endtask\n\n" )


#print(RenderTree(root))

"""
cases.sort(key=lambda x: x['vagueness'])

with open(output_name, "wt") as fp:
    for c in cases:
        assigns = ';\n\t'.join(c['assignments'])
        comment = c['comment']
        match = c['match']
        path = c['path']
        fp.write( f"/* {path} */\n" )
        fp.write( f"24'b{match}: begin /* {comment} */\n\t{assigns};\nend\n" )


for idx1 in range(len(cases)):
    for idx2 in range(idx1 + 1, len(cases)):
        if cases[idx1]['vagueness'] == cases[idx2]['vagueness'] and is_ambiguous(cases[idx1]['match'], cases[idx2]['match']):
            print(f"Ambiguous: {cases[idx1]['match']}  {cases[idx2]['match']}")
"""
