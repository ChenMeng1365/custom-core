#coding:utf-8

# DDU

''' active-call & proxy '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

class object():
    def send(self, attr, val=None, acs='get'):
        if hasattr(self, attr):
            if ( (val is not None) and (acs == 'get') ): acs = 'set' # acs must be set if val exists
            if ( acs in ('get','r') ): return ('ok', getattr(self, attr))
            if ( acs in ('set','w') ): setattr(self, attr, val); return ('ok', f'set {attr}={val}')
        else:
            return ('err', f'No method name {attr}')
    # end def send

    def call(self, process, *messages):
        if hasattr(self, process):
            return ('ok', getattr(self, process)(*messages))
        else:
            return ('err', f'No method name {process}')
    # end def call

    def set_proxy(self, target):
        self.__target__ = target
    # end def set_proxy

    def psend(self, attr, val=None, acs='get'):
        if hasattr(self.__target__, attr):
            if ( (val is not None) and (acs == 'get') ): acs = 'set' # acs must be set if val exists
            if ( acs in ('get','r') ): return ('ok', getattr(self.__target__, attr))
            if ( acs in ('set','w') ): setattr(self.__target__, attr, val); return ('ok', f'set {attr}={val}')
        else:
            return ('err', f'No method name {attr}')
    # end def psend

    def pcall(self, process, *messages):
        if hasattr(self.__target__, process):
            return ('ok', getattr(self.__target__, process)(*messages))
        else:
            return ('err', f'No method name {process}')
    # end def pcall
# end class object

class Missing(object):
    def __init__(self): self.__env__ = {}

    def get(self, key): return self.__env__[key]

    def set(self, key, val): self.__env__[key] = val; return self.__env__[key]

    def __getattr__(self, name): 
        def _missing(*args, **kwargs): return self.__env__[name]
        return _missing()
    # end def getattr
# end class Missing

''' active-trace '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

class NotFound(object):
    def __init__(self, message): self.message = str(message)
    def __repr__(self): return self.message
# end class NotFound

def exist(atom): return type(atom) not in [type(None), NotFound]

class Trace(object):
    def __init__(self, trail): self._trail_ = trail

    @property
    def trail(self): return self._trail_

    @property
    def ender(self): 
        if self._trail_: return self._trail_[-1]
        else: return None
    # end def ender

    def route(node, path):
        target, trails, hops = node, [], path.replace('-','_').split("/")
        if "" in hops: hops.remove("")
        for hop in hops:
            if hasattr(target, hop):
                target = getattr(target, hop)
            else:
                target = NotFound(hop)
            trails.append(target)
            if not exist(target): break
        return Trace(trails)
    # end def route

    def on(node, path):
        parent = None
        target, trails, hops = node, [], path.replace("/*","*").split("/")
        if "" in hops: hops.remove("")
        trails.append(target)
        for hop in hops:
            hopz = hop
            if '*' in hop: hopz = hopz.replace('*','')
            hopi = '_'.join([word for word in hopz.split('-')])
            if hasattr(target, hopi):
                nexthop = getattr(target, hopi)
                parent = target
                if nexthop:
                    target = getattr(target, hopi)
                else:
                    hopn = ''.join([word.capitalize() for word in hopz.split('-')])
                    if hasattr(target, hopn):
                        target = getattr(target, hopn)()
                    elif hasattr(target, hopn+'_'):
                        target = getattr(target, hopn+'_')()
                    else:
                        target = hopi
                if '*' in hop: getattr(parent, hopi).append(target)
                trails.append(target)
            else:
                trails.append(NotFound(hop))
                break
        result = Trace(trails)
        result.set_target(result.ender)
        return result
    # end def on

    def path(path):
        hops = path.replace("/*","*").split("/")
        if "" in hops: hops.remove("")
        return Trace(hops)
    # end def path
# end class trace

def traceroute(obj, path):
    target, hops = obj, path.split("/")
    if "" in hops: hops.remove("")
    for hop in hops:
        if not hasattr(target, hop): return NotFound(hop)
        target = getattr(target, hop)
    return target
# end def traceroute

''' active-import '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

# reg = Register()
# reg.base_import([模块名], 前缀)
# reg.pack_import([[包名, 模块名, 个别前缀*]], 前缀)
# reg.mass_import({包名: [模块名]}, 前缀) or reg.mass_import({(包名,个别前缀*): [模块名]}, 前缀)
# reg.模块别名 or reg.get('模块别名')
class Register(Missing):
    # many aload dict with tagged register
    def mass_import(self, _alist, _header='', _tail=''):
        key_list = []
        for _aitem in _alist.items():
            pkg_sign, pkg_list = _aitem
            if type(pkg_sign)==tuple:
                pkg_name, pkg_head = pkg_sign
            else: 
                pkg_name = pkg_sign
                pkg_head = _header
            importor = __import__(pkg_name,fromlist=pkg_list)
            handlers = [ getattr(importor, submodule) for submodule in pkg_list ]
            for index in range(len(pkg_list)):
                if '=>' in pkg_head: name = pkg_head.split('=>')[-1]
                else: name = pkg_head+pkg_list[index]+_tail
                self.set(name, handlers[index])
                key_list.append(name)
        return key_list
    # end def mass_import

    # many sload list with tagged register
    def base_import(self, _list, _header='', _tail=''):
        key_list = []
        for pkgmod in _list:
            if '=>' in _header: name = _header.split('=>')[-1]
            else: name = _header+pkgmod+_tail
            self.set(name, __import__(pkgmod))
            key_list.append(name)
        return key_list
    # end def base_import

    # many uload list with tagged register
    def pack_import(self, _list, _header='', _tail=''):
        key_list = []
        for pkgmod in _list:
            if len(pkgmod)==3:
                package, submodule, subhead = pkgmod
            else:
                package, submodule = pkgmod
                subhead = _header
            if '=>' in subhead: name = subhead.split('=>')[-1]
            else: name = subhead+submodule+_tail
            self.set(name, getattr(__import__(package,fromlist=[submodule]), submodule))
            key_list.append(name)
        return key_list
    # end def pack_import
# end class register

# nicknames = [from pkg_name import submodule ]
# one package with some submodules
def aload(pkg_name, pkg_list):
    importor = __import__(pkg_name,fromlist=pkg_list)
    return [ getattr(importor, submodule) for submodule in pkg_list ]
# end def aload

# nicknames = [import pkg_name]
# one package with some modules
def sload(*pkg_list): return [__import__(pkg_name) for pkg_name in pkg_list]

# nickname = from pkg_name import module
# one package with one submodule
def uload(pkg_name, module): return getattr(__import__(pkg_name,fromlist=[module]), module)

''' misc '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

def pending(tag='no-tag'): return None

end = 'end'

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
