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

  public getImmCnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunecnv/immunecnvcortable', postTerm);
  }
  public getImmCnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunecnv/immunecnvcorplot', postTerm);
  }
  public getImmCnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunecnv/immunecnvcorsinglegene', postTerm);
  }

}
