import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class MutationApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getSnvTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/snvtable', postTerm);
  }
  public getSnvPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvplot', postTerm);
  }
  public getSnvSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvsinglegeneplot', postTerm);
  }
}
