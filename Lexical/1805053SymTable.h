#include<iostream>
#include<string>
#include<vector>
#include <fstream>
#include <sstream>
using namespace std;

bool verbose = true;
stringstream outputStream;

string getOutputStream(){
    string temp = outputStream.str();
    outputStream.str(std::string());
    return temp;
}
uint32_t sdbm(string str)
    {
        uint32_t hash = 0;
       
        for (char c : str)
            hash = c + (hash << 6) + (hash << 16) - hash;

        return hash;
    }




class SymbolInfo{
    string* Name;
    string* Type;
    SymbolInfo* next;

    public:

    SymbolInfo(string Name, string Type){
        this->Name = new string(Name);
        this->Type = new string(Type);
        this->next = nullptr;
    } 

    ~SymbolInfo(){
        delete Name;
        delete Type;
    } 

    void setNext(SymbolInfo* next){
        this->next = next;
    }

    SymbolInfo* getNext(){

        return this->next;
    }

    string getName(){
        return *Name;
    }

    void printSymbol(){
        outputStream<<"< "<<*Name<<" : "<<*Type<<"> ";
    }



};


class ScopeTable{

    ScopeTable* parentScope;
  
    int n;
    int numChildren;
    string ID;

    public:

    vector<SymbolInfo* > table;

    string getID(){
        return this->ID;
    }

    int getNumChildren(){
        return this->numChildren;
    }

    ScopeTable(int n, string parentID, int order){
        this->numChildren = 0;
        this-> n = n;
        this->ID = parentID+to_string(order);
        for(int i=0;i<n;i++){
            table.push_back(nullptr);
        }
    }

    void incrementNumChildren(){
        this->numChildren ++;
    }

    ~ScopeTable(){
        
        for (std::vector<SymbolInfo*>::iterator i = table.begin(); i != table.end(); ++i) {

        SymbolInfo* p = *i;

        while(p!=nullptr){
                SymbolInfo* next = p->getNext();
                delete p;
                p = next;
            }

        }

        table.clear();
        // delete[] table;
     }




    void setParentScope(ScopeTable* parentScope){
        this->parentScope = parentScope;
    }

    ScopeTable* getParentScope(){
        return this->parentScope;
    }

    bool insertSymbol(string Name, string Type){
        outputStream.str(std::string());
        int k = sdbm(Name)%this->n;
       

        int offset = 0;
        
        
        if (this->table[k] == nullptr)
            this->table[k] = new SymbolInfo(Name, Type);
        
        else{
        
            SymbolInfo* current = this->table[k];
            offset = 1;

            while (current->getNext()!= nullptr){
                if(current->getName().compare(Name)==0){
                    if(verbose){
                    current->printSymbol();
                    outputStream<<" already exists in current ScopeTable"<<endl;
                    }
                    return false;
                }

                offset++;
                current = current->getNext();
            }

            if(current->getName().compare(Name)==0){
                if(verbose){
                        current->printSymbol();
                        outputStream<<" already exists in current ScopeTable"<<endl;
                }
                    return false;
                }


            current->setNext(new SymbolInfo(Name, Type));
        }
        
        string to_print = "Inserted  <" + Name +" , " + Type + "> in ScopeTable# "+this->getID()+" at position "+to_string(k)+", "+ to_string(offset);
        if (verbose)
            outputStream<< to_print <<endl;
        return true;
            
    }
    
    bool deleteSymbol(string Name){

        int k = sdbm(Name)%this->n;
        int offset = 0;
        //list empty
        if (this->table[k] == nullptr){
            if (verbose)
                outputStream<<Name<<" not found"<<endl;
            return false;
        }
    

        SymbolInfo* current = this->table[k];

        //first Item is to be removed
        if (current->getName().compare(Name)==0){
            this->table[k] = current->getNext();
            delete current; 
            if (verbose)
             outputStream<<"Deleted Entry " << k<<", "<< offset <<" from current ScopeTable"<<endl;
            return true;
        }


        bool found_flag = false;
        SymbolInfo* before = nullptr;
        

        offset = 0;
        while (current != nullptr ){
            
            if (current->getName().compare(Name)==0){
                found_flag = true;
                break;
            }
            
            before = current;
            current = current->getNext();
            offset++;
        }

        if (found_flag){
            before->setNext(current->getNext());
            delete current; 

            if (verbose)
             outputStream<<"Deleted Entry " << k<<", "<< offset <<" from current ScopeTable"<<endl;
        }
        else{
            if (verbose)
             outputStream<<Name<<" not found"<<endl;
        }

        return found_flag;

    }
    
    SymbolInfo* lookupSymbol(string Name){
        
        int k = sdbm(Name)%this->n;
       
        int offset = 0;
        
        SymbolInfo* current = this->table[k];

        while (current != nullptr ){

            if (current->getName().compare(Name)==0)
                break;
            
            current = current->getNext();
            offset++;
        }
        
        if (current!=nullptr)
            if (verbose)
             outputStream<<"Found in ScopeTable# "+this->getID()+" at position "+to_string(k)+", "+ to_string(offset)<<endl;
        // else
        //     outputStream<<"Not found in Current Scope Table"<<endl;
        return current;


    }

    

    void printOneRow(int k){
        if (this->table[k] == nullptr)
            return;

        SymbolInfo* current = this->table[k];

        while (current != nullptr ){
         
            current -> printSymbol(); 
            outputStream<<" ";
            current = current->getNext();
        }

        

        
    }
    void printScopeTable(){

        outputStream<<"ScopeTable# "<<this->getID()<<endl;

        for (int i=0;i<n;i++){
            if (this->table[i] == nullptr)
                continue;;
            outputStream<<i<<"--> ";
            printOneRow(i);
            outputStream<<endl;

        }

        outputStream<<endl;
    }
};


class SymbolTable{
    ScopeTable* current;
    int n; //SCOPETABLE SIZE
    int globalScopeCount;

    public:

    SymbolTable(int n){
        this->n = n;
        this->globalScopeCount = 1;
        current = new ScopeTable(n, "", globalScopeCount);
        current->setParentScope(nullptr);
    }


    void enterScope(){

        string parentID;
        int order;
        if (current != nullptr){
            parentID = current->getID()+".";
            current->incrementNumChildren();
            order = current->getNumChildren();
        }  
        else{
            parentID = "";
            this->globalScopeCount++;
            order = this->globalScopeCount;  
        }

        ScopeTable* temp = current;
       

        current = new ScopeTable(n, parentID, order);
    
        current->setParentScope(temp);
      
        if (verbose)
             outputStream<<"New ScopeTable with id "+current->getID() + " created"<<endl;
    }

    void printCurrentScopeID(){
        if (current == nullptr)
            return;

        outputStream<<current->getID()<<endl;
    }

    void exitScope(){
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot exit."<<endl;
            return;
        }

        ScopeTable* temp = current->getParentScope();
        if (verbose)
             outputStream<<"ScopeTable with id "+current->getID()+" removed"<<endl;
        delete current; 
        current = temp;
    }

    bool insert(string Name, string Type){
        
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot Insert."<<endl;
            return false;
        }
        return current->insertSymbol(Name,Type);
    }

    bool remove(string Name){
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot Remove."<<endl;
            return false;
        }

        bool flag = current->deleteSymbol(Name);
     
        return flag;
    }

    SymbolInfo* lookup(string Name){
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot Lookup."<<endl;
            return nullptr;
        }

        ScopeTable* toSearch = current;

        while (toSearch != nullptr){
            SymbolInfo* returnVal = toSearch->lookupSymbol(Name);
            if (returnVal!=nullptr)
                return returnVal;
            toSearch = toSearch->getParentScope();
           
        }

        outputStream<<"Not found"<<endl;
        return nullptr;
    }

    void printCurrentScopeTable(){
        outputStream.str(std::string());
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot Print."<<endl;
            return;
        }
        current->printScopeTable();
    }

    void recurseTablesForPrinting(ScopeTable* x){
        if (x==nullptr)
            return;
        
        x->printScopeTable();
        recurseTablesForPrinting(x->getParentScope());

    };


    void printAllScopeTable(){
        outputStream.str(std::string());
 
        if (current == nullptr){
            outputStream<<"No current Scope. Cannot Print."<<endl;
            return;
        }
        ScopeTable* x = current;
        recurseTablesForPrinting(x);
    }





};


vector<string> stringSplit(string str){
    stringstream ss(str);
    string temp;
    vector<string> words;


    while(ss){
        ss>>temp;
        words.push_back(temp);
    }
    return words;
}
/*
int main(){

    string str;
    int n;
 
    
    ifstream inputFile("1805053input.txt"); 

    inputFile >> n;
    SymbolTable table(n);
    

   while (getline (inputFile, str))  {
        
        vector<string> words = stringSplit(str);

        if (words[0].compare("I")==0){
            string name = words[1];
            string value = words[2];
            table.insert(name,value);
        }
        else if (words[0].compare("L")==0){
            string temp = words[1];
            table.lookup(temp);
        }
        else if (words[0].compare("D")==0){
            string temp = words[1];
            table.remove(temp);
        }
        else if (words[0].compare("P")==0){
            if (words[1].compare("A")==0)
                table.printAllScopeTable();
            else if (words[1].compare("C")==0)
                table.printCurrentScopeTable();
        }
        else if (words[0].compare("S")==0){
            table.enterScope();
        }
        else if (words[0].compare("E")==0){
            table.exitScope();
        }


        
       
       
    }
    inputFile.close();

}
*/
