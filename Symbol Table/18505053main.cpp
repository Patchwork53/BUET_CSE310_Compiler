#include<iostream>
#include<string>
#include<vector>
#include<fstream>
#include<sstream>

using namespace std;

int sdbm(string str)
    {
        int hash = 0;
       
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
        cout<<"< "<<*Name<<" : "<<*Type<<"> ";
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

        int k = sdbm(Name)%this->n;
       

        int offset = 0;
        
        
        if (this->table[k] == nullptr)
            this->table[k] = new SymbolInfo(Name, Type);
        
        else{
        
            SymbolInfo* current = this->table[k];
            offset = 1;

            while (current->getNext()!= nullptr){
                if(current->getName().compare(Name)==0){
                    current->printSymbol();
                    cout<<" already exists in current ScopeTable"<<endl<<flush;
                    return false;
                }

                offset++;
                current = current->getNext();
            }

            if(current->getName().compare(Name)==0){
                    current->printSymbol();
                    cout<<" already exists in current ScopeTable"<<endl<<flush;
                    return false;
                }


            current->setNext(new SymbolInfo(Name, Type));
        }

        cout<<"Inserted in ScopeTable# "+this->getID()+" at position "+to_string(k)+", "+ to_string(offset)<<endl<<flush;
        return true;
            
    }
    
    bool deleteSymbol(string Name){

        int k = sdbm(Name)%this->n;
        int offset = 0;
        //list empty
        if (this->table[k] == nullptr){
            cout<<Name<<" not found"<<endl<<flush;
            return false;
        }
    

        SymbolInfo* current = this->table[k];

        //first Item is to be removed
        if (current->getName().compare(Name)==0){
            this->table[k] = current->getNext();
            delete current; 
            cout<<"Deleted Entry " << k<<", "<< offset <<" from current ScopeTable"<<endl<<flush;
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

            cout<<"Deleted Entry " << k<<", "<< offset <<" from current ScopeTable"<<endl<<flush;
        }
        else{
            cout<<Name<<" not found"<<endl<<flush;
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
            cout<<"Found in ScopeTable# "+this->getID()+" at position "+to_string(k)+", "+ to_string(offset)<<endl<<flush;
        // else
        //     cout<<"Not found in Current Scope Table"<<endl<<flush;
        return current;


    }

    

    void printOneRow(int k){
        if (this->table[k] == nullptr)
            return;

        SymbolInfo* current = this->table[k];

        while (current != nullptr ){
         
            current -> printSymbol(); 
            cout<<" ";
            current = current->getNext();
        }

        

        
    }
    void printScopeTable(){

        cout<<"ScopeTable# "<<this->getID()<<endl<<flush;

        for (int i=0;i<n;i++){
            cout<<i<<"--> ";
            printOneRow(i);
            cout<<endl<<flush;

        }

        cout<<endl<<flush;
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
      
        cout<<"New ScopeTable with id "+current->getID() + " created"<<endl<<flush;
    }

    void printCurrentScopeID(){
        if (current == nullptr)
            return;

        cout<<current->getID()<<endl<<flush;
    }

    void exitScope(){
        if (current == nullptr){
            cout<<"No current Scope. Cannot exit."<<endl;
            return;
        }

        ScopeTable* temp = current->getParentScope();
        cout<<"ScopeTable with id "+current->getID()+" removed"<<endl<<flush;
        delete current; 
        current = temp;
    }

    bool insert(string Name, string Type){
        
        if (current == nullptr){
            cout<<"No current Scope. Cannot Insert."<<endl;
            return false;
        }
        return current->insertSymbol(Name,Type);
    }

    bool remove(string Name){
        if (current == nullptr){
            cout<<"No current Scope. Cannot Remove."<<endl;
            return false;
        }

        bool flag = current->deleteSymbol(Name);
     
        return flag;
    }

    SymbolInfo* lookup(string Name){
        if (current == nullptr){
            cout<<"No current Scope. Cannot Lookup."<<endl;
            return nullptr;
        }

        ScopeTable* toSearch = current;

        while (toSearch != nullptr){
            SymbolInfo* returnVal = toSearch->lookupSymbol(Name);
            if (returnVal!=nullptr)
                return returnVal;
            toSearch = toSearch->getParentScope();
           
        }

        cout<<"Not found"<<endl<<flush;
        return nullptr;
    }

    void printCurrentScopeTable(){
        if (current == nullptr){
            cout<<"No current Scope. Cannot Print."<<endl;
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
        if (current == nullptr){
            cout<<"No current Scope. Cannot Print."<<endl;
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