function result=crawler(in_struct,init_result,fct_handler)
%adr,res:struct
result=init_result;
if isstruct(in_struct)
    in_fields=fieldnames(in_struct);
    for i=1:length(in_fields)
        if isstruct([in_struct.(in_fields{i})])
            cur_adr=result(end).adr;
            result(end).adr=[char(cur_adr) '.' char(in_fields{i})];
            result=crawler(in_struct.(in_fields{i}),result,fct_handler);
            t=struct();
            t.adr=cur_adr;
            t.res=[];
            result=[result;t];
        else
            try
                result(end).res=fct_handler([in_struct]);
            catch
            end
            return
        end
    end
end
end

