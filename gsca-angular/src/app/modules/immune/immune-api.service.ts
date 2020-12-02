import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root'
})
export class ImmuneApiService extends BaseHttpService {

  constructor(http: HttpClient) { 
    super(http);
  }
  // immune cnv
  public getImmCnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunecnv/immcnvcortable', postTerm);
  }
  public getImmCnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunecnv/immcnvcorplot', postTerm);
  }
  public getImmCnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunecnv/immcnvcorsinglegene', postTerm);
  }

  // immune expression
  public getImmExprCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immuneexpr/immexprcortable', postTerm);
  }
  public getImmExprCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immuneexpr/immexprcorplot', postTerm);
  }
  public getImmExprCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immuneexpr/immexprcorplot', postTerm);
  }
  // immune snv
  // immune methylation
}
