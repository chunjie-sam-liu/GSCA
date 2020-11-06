import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MutationComponent } from './mutation.component';

describe('MutationComponent', () => {
  let component: MutationComponent;
  let fixture: ComponentFixture<MutationComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MutationComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MutationComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
