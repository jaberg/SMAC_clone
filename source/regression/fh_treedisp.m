function fh_treedisp(JavaTree,model,func,varargin)
    % treedisp doesn't work with nodesize and parent being integer 
    % (which they totally should be ...)
    if (nargin < 3) 
        func = [];
    end
    
    if JavaTree.preprocessed
        warning('Tree has been preprocessed. Means and the other stats should still be accurate, but some nodes may have been pruned.\nMarginal predictions are not shown in this graph.');
    end

    Tree = struct;
    Tree.method = 'regression';
    Tree.node = double(JavaTree.node + 1);
    Tree.parent = double(JavaTree.parent);
    Tree.parent(2:end) = Tree.parent(2:end)+1;
    Tree.var = JavaTree.var;
    Tree.children = double(JavaTree.children);
    Tree.children(Tree.children ~= 0) = Tree.children(Tree.children ~= 0) + 1;
    Tree.nodesize = double(JavaTree.nodesize);
    Tree.class = JavaTree.nodepred;
    if model.options.logModel == 1
        Tree.class = 10.^Tree.class;
    end
    Tree = fillTreeClasses(Tree, 1);
    if model.options.logModel == 3
        Tree.class = 10.^Tree.class;
    end
    Tree.nodeprob = zeros(size(Tree.node));
    Tree.nodeerr = double(zeros(size(Tree.node)));
    Tree.risk = zeros(size(Tree.node));
    Tree.npred = JavaTree.npred;
    Tree.catcols = double(model.cat);
    if ~isempty(model.names)
        Tree.names = model.names;
    end

    csplit = JavaTree.catsplit;
    if ~iscell(csplit)
        csplit = mat2cell(csplit, ones(size(csplit, 1), 1), size(csplit, 2));
    end
    nnode = length(JavaTree.node);
    Tree.cut = cell(nnode,1);
    for inode=1:nnode
        if JavaTree.var(inode)<0 % categorical variable
            icat = JavaTree.cut(inode)+1;
            Tree.cut{inode} = {find(csplit{icat}==0)', find(csplit{icat}==1)'};

            if ~isempty(func)
                i = -JavaTree.var(inode);
                if i < length(model.kept_Theta_columns)
                    i = model.kept_Theta_columns(i);
                    Tree.cut{inode}{1} = str2double(func.all_values{i}(Tree.cut{inode}{1}));
                    Tree.cut{inode}{2} = str2double(func.all_values{i}(Tree.cut{inode}{2}));
                end
            end
        else % continuous variable (>0) or leaf (=0)
            Tree.cut{inode} = JavaTree.cut(inode);

            if ~isempty(func) 
                i = JavaTree.var(inode);
                if i ~= 0 && i < length(model.kept_Theta_columns) % continuous variable
                    i = model.kept_Theta_columns(i);
                    Tree.cut{inode} = Tree.cut{inode} * (func.transformed_param_upper_bound(i)-func.transformed_param_lower_bound(i)) + func.transformed_param_lower_bound(i);
                    Tree.cut{inode} = param_back_transform(Tree.cut{inode}, func.param_trafo(i));
                    if func.is_integer_param(i)
                        Tree.cut{inode} = round(Tree.cut{inode});
                    end
                end
            end
        end
    end

    Tree = classregtree(Tree);

    treedisp(Tree,varargin{:});
end
function Tree = fillTreeClasses(Tree, node)
    if Tree.var(node) == 0
        return;
    end
    left_kid = Tree.children(node, 1);
    right_kid = Tree.children(node, 2);
    Tree = fillTreeClasses(Tree, left_kid);
    Tree = fillTreeClasses(Tree, right_kid);
    Tree.class(node) = (Tree.class(left_kid)*Tree.nodesize(left_kid) + Tree.class(right_kid)*Tree.nodesize(right_kid)) / Tree.nodesize(node);
end